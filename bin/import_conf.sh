#!/bin/bash

# Import from tgz.enc password encoded tgz
# ~/credentials_and_ymls.tgz.enc
# to ~/opendax

cd ~
if [ ! -d ./opendax ]; then
 echo "Cannot find opendax dir in home dir."
 exit
fi

basename=opendax_conf

if [ ! -f ./$basename.tgz.enc ]; then
 echo "Cannot find $basename.tgz.enc in home dir."
 exit
fi

openssl aes-256-cbc -d -pbkdf2 -in $basename.tgz.enc -out $basename.tgz
if [ $? -gt 0 ]; then
 exit
fi
tar xvzf $basename.tgz
rm -f $basename.tgz

echo ----
echo Successfully extracted from ~/$basename.tgz.enc
