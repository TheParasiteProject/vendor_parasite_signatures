#!/bin/bash

AVBTOOL=../../../external/avb/avbtool.py
MAKEKEY=./make_key

OUTDIR=../../private-signatures

CERTIFICATE_FILES_TXT="certificate-files.txt"

# Check whether dir or symlink exists already
if [ ! -d $OUTDIR ] || [ ! -f $OUTDIR ]; then
    mkdir -p $OUTDIR
fi

if [ "$#" -gt 1 ] && [ "$#" -lt 3 ]; then
    SKIP_PROMPT=true
    echo 
fi

function confirm() {
    while true; do
        read -r -p "$1 (yes/no): " input
        case "$input" in
            [yY][eE][sS]|[yY]) echo "yes"; return ;;
            [nN][oO]|[nN]) echo "no"; return ;;
            *) ;;
        esac
    done
}

function prompt_key_size() {
    while true; do
        read -p "$1" input
        if [[ "$input" == "2048" || "$input" == "4096" ]]; then
            echo "$input"
            break
        fi
    done
}

function prompt() {
    while true; do
        read -p "$1" input
        if [[ -n "$input" ]]; then
            echo "$input"
            break
        fi
    done
}

function user_input() {
    if [[ $(confirm "Do you want to customize the key size and subject?") == "yes" ]]; then
        key_size=$(prompt_key_size "Enter the key size (2048 or 4096, APEX will always use 4096): ")
        country_code=$(prompt "Enter the country code (e.g., US): ")
        state=$(prompt "Enter the state or province (e.g., California): ")
        city=$(prompt "Enter the city or locality (e.g., Mountain View): ")
        org=$(prompt "Enter the organization (e.g., Android): ")
        ou=$(prompt "Enter the organizational unit (e.g., Android): ")
        cn=$(prompt "Enter the common name (e.g., Android): ")
        email=$(prompt "Enter the email address (e.g., android@android.com): ")

        echo "Subject information to be used:"
        echo "Key Size: $key_size"
        echo "Country Code: $country_code"
        echo "State/Province: $state"
        echo "City/Locality: $city"
        echo "Organization (O): $org"
        echo "Organizational Unit (OU): $ou"
        echo "Common Name (CN): $cn"
        echo "Email Address: $email"

        if [[ $(confirm "Is this information correct?") != "yes" ]]; then
            echo "Generation aborted."
            exit 0
        fi
    else
        key_size='2048'
        country_code='US'
        state='California'
        city='Mountain View'
        org='Android'
        ou='Android'
        cn='Android'
        email='android@android.com'
    fi

    subject="/C=$country_code/ST=$state/L=$city/O=$org/OU=$ou/CN=$cn/emailAddress=$email"
}

function generate_keys() {
    for file in `cat $1`
    do
        if [[ (-f "$2/${file}.x509.pem" && -f "$2/${file}.pk8" && -f "$2/${file}-private.pem") ||
              (-f "$2/${file}.certificate.override.x509.pem" && -f "$2/${file}.certificate.override.pk8" && -f "$2/${file}.certificate.override-private.pem") ]]; then
            echo "$file already exists. Skipping..."
        else
            if [[ $file = *".override" ]]; then
                bash $MAKEKEY "$2/$file" "$subject" 4096
            else
                bash $MAKEKEY "$2/$file" "$subject" $key_size
            fi
        fi
    done

    if [[ ! -f "$2/avb_pkmd.bin" ]]; then
        # Generate avb_pkmd.bin
        $AVBTOOL extract_public_key \
          --key "$2/releasekey-private.pem" \
          --output "$2/avb_pkmd.bin"
    fi
}

if [[ $SKIP_PROMPT = true ]]; then
    subject="$1"
    if ! [[ $2 =~ ^[0-9]+$ ]]; then
      key_size=2048
    else
      key_size="$2"
    fi
else
    user_input
fi

generate_keys $CERTIFICATE_FILES_TXT $OUTDIR
