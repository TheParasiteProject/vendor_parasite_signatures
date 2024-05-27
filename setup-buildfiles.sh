#!/bin/bash

CWD=$(pwd)

ANDROIDBP="Android.bp"
OVERRIDEMK="override.mk"
CERTIFICATE_FILES_TXT="certificate-files.txt"

rm -f data/*.pk8 data/*.x509.pem

function write_blueprint_header() {
    if [ -f "$ANDROIDBP" ]; then
        rm "$ANDROIDBP"
    fi

    cat << EOF >> "$ANDROIDBP"
// Automatically generated file. DO NOT MODIFY

EOF
}

function write_blueprint_packages() {
    local CRTNAME=$1
    local CRTDIRNAME=$2

    printf 'android_app_certificate {\n' >> "$ANDROIDBP"
    printf '\tname: "%s",\n' "$CRTNAME" >> "$ANDROIDBP"
    printf '\tcertificate: "%s",\n' "$CRTDIRNAME/$CRTNAME" >> "$ANDROIDBP"
    printf '}\n' >> "$ANDROIDBP"
    printf '\n' >> "$ANDROIDBP"

    unset CRTNAME
    unset CRTDIRNAME
}

function write_certificate_overrides_makefile_header() {
    if [ -f "$OVERRIDEMK" ]; then
        rm "$OVERRIDEMK"
    fi

    cat << EOF >> "$OVERRIDEMK"
# Automatically generated file. DO NOT MODIFY

EOF
    printf '%s\n' "PRODUCT_CERTIFICATE_OVERRIDES := \\" >> "$OVERRIDEMK"
}

function write_product_certificate_overrides() {
    local CRTNAME=$1
    local PKGTOOVERRIDECRT=
    if [[ $CRTNAME == *".certificate.override" ]]; then
        PKGTOOVERRIDECRT="${1%\.certificate\.override}"
    else
        PKGTOOVERRIDECRT="${1%\.override}"
    fi

    printf '\t%s\n' "$PKGTOOVERRIDECRT:$CRTNAME \\" >> "$OVERRIDEMK"

    unset CRTNAME
    unset PKGTOOVERRIDECRT
}

function create_symlinks() {
    if [ -z $1 ] || [ -z $2 ]; then
        return
    fi

    local TARGETFILE=$1
    local DIRTOWORK=$2

    cd "$DIRTOWORK"

    fileName=`basename $TARGETFILE`

    certNameDest="$TARGETFILE"
    if [ $fileName == releasekey ]; then
        certNameDest=testkey
    fi

    ln -fs $certNameDest.pk8 "$fileName".pk8
    ln -fs $certNameDest.x509.pem "$fileName".x509.pem

    cd $CWD

    unset TARGETFILE
    unset DIRTOWORK
}

write_blueprint_header
write_certificate_overrides_makefile_header

for certs in `cat $CERTIFICATE_FILES_TXT`; do
    if [[ $certs == *".override" ]]; then
        write_blueprint_packages "$certs" data
        write_product_certificate_overrides "$certs"
    fi
    create_symlinks ../../data/"$certs" data
done

create_symlinks data/releasekey data
