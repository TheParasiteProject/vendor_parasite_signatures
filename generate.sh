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
		[yY][eE][sS] | [yY])
			echo "yes"
			return
			;;
		[nN][oO] | [nN])
			echo "no"
			return
			;;
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
	local filesRaw=$(cat $1)
	local files=()
	for file in ${filesRaw[@]}; do
		if [[ $file == *:* ]]; then
			file=$(echo $file | cut -d ":" -f 2)
		fi
		files+=($file)
	done
	files=($(printf "%q\n" "${files[@]}" | sort -u))
	for file in ${files[@]}; do
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

	if [[ ! -f "$2/lineageos_pubkey" ]]; then
		# Generate lineageos_pubkey for verifying
		openssl rsa -in "$2/releasekey-private.pem" -RSAPublicKey_out -out "$2/lineageos_pubkey"
	fi

	if [[ ! -f "$2/avb_pkmd.bin" ]]; then
		# Generate avb_pkmd.bin
		$AVBTOOL extract_public_key \
			--key "$2/releasekey-private.pem" \
			--output "$2/avb_pkmd.bin"
	fi
}

function generate_keystore() {
	# generate the keystore and show the result
	local storepassword="android"
	local outdir="$1"
	local outkeystore="$outdir/aosp.keystore"

	if [ $# -gt 0 ]; then
		outdir="$1"
	fi
	if [ $# -gt 1 ]; then
		storepassword="$2"
	fi
	if [ -f "$outkeystore" ]; then
		echo "Keystore already exists: $outkeystore !"
		return 1
	fi

	local keynames=("media" "releasekey" "shared" "platform")

	for keyname in ${keynames[@]}; do
		if [ ! -e "$outdir/$keyname.pk8" ] || [ ! -e "$outdir/$keyname.x509.pem" ]; then
			echo "$keyname key does not exists!"
			return 1
		fi
	done
	for keyname in ${keynames[@]}; do
		echo "Importing $keyname to $outkeystore"
		openssl pkcs8 \
			-inform DER \
			-nocrypt \
			-in "$outdir/$keyname.pk8" \
			-out "$outdir/$keyname.pem"
		openssl pkcs12 \
			-export \
			-in "$outdir/$keyname.x509.pem" \
			-inkey "$outdir/$keyname.pem" \
			-out "$outdir/$keyname.p12" \
			-password pass:android \
			-name "$keyname"
		keytool \
			-noprompt -importkeystore \
			-deststorepass "$storepassword" \
			-destkeystore "$outkeystore" \
			-srckeystore "$outdir/$keyname.p12" \
			-srcstoretype PKCS12 \
			-srcstorepass android
		rm $outdir/$keyname.p12 $outdir/$keyname.pem
	done
	keytool -list -v -keystore "$outkeystore" -storepass "$storepassword"
	echo "Done importing keys!"
	return 0
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
generate_keystore $OUTDIR
