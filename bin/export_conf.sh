#!/bin/bash

# Notice)
# This is just a sample,
# Use bundle exec rake confpack

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

basename=opendax_conf

if [ -f ./$basename.tgz.enc ]; then
 cp -f $basename.tgz.enc $basename.tgz.`date "+%Y%m%d_%H%M%S"`.enc
fi
tar cvzf $basename.tgz --exclude sample.app.yml \
  opendax_credentials opendax/config/secrets/*.key* \
  opendax/config/app.yml.d/*.yml opendax/config/deploy.yml \
  opendax/config/utils.yml
openssl aes-256-cbc -e -pbkdf2 -in $basename.tgz -out $basename.tgz.enc
if [ $? -gt 0 ]; then
 rm -f $basename.tgz
 exit
fi
rm -f $basename.tgz
chmod 600 $basename.tgz.enc

echo ----
echo Successfully placed ~/$basename.tgz.enc
