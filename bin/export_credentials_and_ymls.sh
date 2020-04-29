#!/bin/bash

# Export to homedir in password encoded tgz

# 1) All customized *.yml configs in opendax
# 2) ../opendax_credentials/*

cd ~
if [ ! -d ./opendax ]; then
 echo "Cannot find opendax dir in home dir."
 exit
fi
if [ ! -d ./opendax_credentials ]; then
 echo "Cannot find opendax_credentials dir in home dir."
 exit
fi

basename=opendax_credentials_and_ymls

if [ -f ./$basename.tgz.enc ]; then
 cp -f $basename.tgz.enc $basename.tgz.`date "+%Y%m%d_%H%M%S"`.enc
fi
tar cvzf $basename.tgz opendax_credentials opendax/config/app.yml.d opendax/config/deploy.yml opendax/config/utils.yml
openssl aes-256-cbc -e -pbkdf2 -in $basename.tgz -out $basename.tgz.enc
if [ $? -gt 0 ]; then
 rm -f $basename.tgz
 exit
fi
rm -f $basename.tgz
chmod 600 $basename.tgz.enc

echo ----
echo Successfully placed ~/$basename.tgz.enc
