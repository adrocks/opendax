#!/bin/bash -x

# Update Cloudflare's IP

#  For user "deploy"

if [ $USER != "deploy" ]; then
    echo "You are not user 'deploy'"
    exit
fi

read -p "Update Cloudflare's IP. OK? (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "Abort." ; exit ;; esac

echo "Finished."