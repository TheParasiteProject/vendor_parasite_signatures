#!/bin/bash

CWD=$(pwd)

ANDROIDBP="Android.bp"

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

for certs in `cat certificate-files.txt`; do
    if [[ $certs == *".override" ]]; then
        write_blueprint_packages "$certs" data
    fi
    create_symlinks ../../data/"$certs" data
done

create_symlinks data/releasekey data
