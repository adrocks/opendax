#!/bin/bash -x

source /home/$USER/opendax/bin/install_lib.sh

install_firewall() {
  sudo bash <<EOS
  apt install -y -q ufw
  systemctl enable ufw
  systemctl restart ufw
  ufw allow ssh
  ufw allow 822
  ufw allow 80/tcp
  ufw allow 8080/tcp
  ufw allow 1337/tcp
  ufw allow 443/tcp
  ufw allow 5000/tcp
  yes | ufw enable
  ufw reload
  ufw status verbose
EOS
}

# install_lib.sh
fix_system
install_core
log_rotation
install_docker
activate_gcloud
install_ruby
prepare_docker_volumes

#
install_firewall
