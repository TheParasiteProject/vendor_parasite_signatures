#!/bin/bash

subject=$1
if [ -z "$subject" ]
then
    echo -e "Subject not specified!"
    echo -e "Use dummy subject"
    subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
fi

outdir=../private-signatures

# Check whether dir or symlink exists already
if [ ! -d $outdir ] || [ ! -f $outdir ]; then
    mkdir -p $outdir
fi

MAKEKEY=./make_key

for file in `cat certificate-files.txt`
do
    if [[ $file = *".override" ]]; then
        bit=4096
    fi
    bash $MAKEKEY $outdir/"$file" "$subject" $bit
    unset bit
done
