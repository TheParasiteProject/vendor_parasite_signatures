#!/bin/bash

subject=$1
if [ -z "$subject" ]
then
    echo -e "Subject not specified!"
    echo -e "Use dummy subject"
    subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
fi

outdir=../data

MAKEKEY=./make_key

for file in `cat certificate-files.txt` `cat certificate-override-files.txt`
do
    bash $MAKEKEY $outdir/"$file" "$subject" rsa
done
