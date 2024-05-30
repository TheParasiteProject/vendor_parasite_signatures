#!/bin/bash

CWD=$(pwd)

# Base location: $ANDROID_ROOT/vendor/parasite-signatures/common/data
PRIVATE_KEY_DIR=../../../private-signatures

OUT_DIR_ROOT="common"
OUTDIR="$OUT_DIR_ROOT/data"
OUT="data"

rm -Rf $OUT_DIR_ROOT
mkdir -p $OUTDIR

ANDROIDBP="$OUT_DIR_ROOT/Android.bp"
PRODUCTMK="$OUT_DIR_ROOT/certificates.mk"
CERTIFICATE_FILES_TXT="certificate-files.txt"

function write_blueprint_header() {
    if [ -f "$ANDROIDBP" ]; then
        rm "$ANDROIDBP"
    fi

    cat << EOF >> "$ANDROIDBP"
// Automatically generated file. DO NOT MODIFY

EOF
}

function write_blueprint_packages() {
    local cert_dir_name=$2

    local files=(`cat $1 | grep '.override'`)
    for ((i=0; i<"${#files[@]}"; i++)); do
        file_name="${files[$i]}"
        printf 'android_app_certificate {\n' >> "$ANDROIDBP"
        printf '\tname: "%s",\n' "$file_name" >> "$ANDROIDBP"
        printf '\tcertificate: "%s",\n' "$cert_dir_name"/"$file_name" >> "$ANDROIDBP"
        printf "}\n" >> "$ANDROIDBP"
        if [ $i -lt $((${#files[@]} - 1)) ]; then
            printf "\n" >> "$ANDROIDBP"
        fi
    done
}

function write_certificate_overrides_makefile_header() {
    if [ -f "$PRODUCTMK" ]; then
        rm "$PRODUCTMK"
    fi

    cat << EOF >> "$PRODUCTMK"
# Automatically generated file. DO NOT MODIFY

EOF
}

function write_product_certificate_overrides() {
    printf '%s\n' "PRODUCT_CERTIFICATE_OVERRIDES := \\" >> "$PRODUCTMK"

    local files=(`cat $1 | grep '.override'`)
    local file_name=
    local file_to_overrides=
    for ((i=0; i<"${#files[@]}"; i++)); do
        file_name="${files[$i]}"
        if [[ $file_name == *".certificate.override" ]]; then
            file_to_overrides="${file_name%\.certificate\.override}"
        else
            file_to_overrides="${file_name%\.override}"
        fi
        printf '\t%s' "$file_to_overrides:$file_name" >> "$PRODUCTMK"
        if [ $i -lt $((${#files[@]} - 1)) ]; then
            printf '%s\n' " \\" >> "$PRODUCTMK"
        else
            printf '\n\n' >> "$PRODUCTMK"
        fi
    done

    echo 'PRODUCT_DEFAULT_DEV_CERTIFICATE := $(CERTIFICATE_COMMON)/data/releasekey' >> "$PRODUCTMK"
    echo 'PRODUCT_OTA_PUBLIC_KEYS := $(CERTIFICATE_COMMON)/data/releasekey.x509.pem' >> "$PRODUCTMK"
}

function create_symlinks() {
    if [ -z $1 ] || [ -z $2 ]; then
        return
    fi

    local target_file=$1
    local dir_to_work=$2
    local is_cert=$3

    cd "$dir_to_work"

    local file_name=`basename $target_file`

    local file_name_with_dest="$target_file"
    if [ $file_name == releasekey ]; then
        file_name_with_dest=testkey
    fi

    if [[ $is_cert = true ]]; then
        ln -fs $file_name_with_dest.pk8 "$file_name".pk8
        ln -fs $file_name_with_dest.x509.pem "$file_name".x509.pem
    else
        ln -fs $file_name_with_dest "$file_name"
    fi

    cd $CWD
}

write_blueprint_header
write_certificate_overrides_makefile_header
write_blueprint_packages $CERTIFICATE_FILES_TXT $OUT
write_product_certificate_overrides $CERTIFICATE_FILES_TXT

for certs in `cat $CERTIFICATE_FILES_TXT`; do
    create_symlinks "$PRIVATE_KEY_DIR/$certs" $OUTDIR true
done

create_symlinks $OUTDIR/releasekey $OUTDIR true
create_symlinks "$PRIVATE_KEY_DIR/avb_pkmd.bin" $OUTDIR
