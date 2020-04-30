#!/bin/bash -x

# Ubuntu 18.04 LTS minimal

COMPOSE_VERSION="1.23.2"
COMPOSE_URL="https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)"

# Needed for elasticsearch
fix_system() {
  sudo bash <<EOS
  echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
  sysctl -p
EOS
}

# Opendax bootstrap script
# Note) DEBIAN_FRONTEND for tzdata install screen stop
# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
# At first, sleep for seconds to initial image to be updated by GCP infra or other.
install_core() {
  sudo bash <<EOS
sleep 10
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -y tzdata
ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
apt-get install -y -q git tmux gnupg2 dirmngr dbus htop curl libmariadbclient-dev-compat build-essential
apt-get install -y -q vim
EOS
}

log_rotation() {
  sudo bash <<EOS
mkdir -p /etc/docker
echo '
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "10"
  }
}' > /etc/docker/daemon.json
EOS
}

# Docker installation
install_docker() {
  export VERSION=19.03.8
  curl -fsSL https://get.docker.com/ | bash
  sudo bash <<EOS
usermod -a -G docker $USER
curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
EOS
}

activate_gcloud() {
  sudo -u deploy bash <<EOS
  gcloud auth configure-docker --quiet
EOS
}

install_ruby() {
  sudo -u deploy bash <<EOS
  gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable
  echo 'alias ber="bundle exec rake"' >> ~/.bashrc
  echo 'alias be="bundle exec"' >> ~/.bashrc
EOS
}

prepare_docker_volumes() {
  sudo -u deploy bash <<EOS
  mkdir -p /home/deploy/docker_volumes
  chmod a+w /home/deploy/docker_volumes
EOS
}

# Install Let's encrypt(ssl)
# apt stuff is for Ubuntu 18.04 so, check again for Ubuntu 20.04
# https://certbot.eff.org/lets-encrypt/ubuntufocal-other
# 
# You have to do manual install steps after terraform install.
# See terraform/README.md
# 
install_mailserver() {
  sudo -u deploy bash <<EOS
  sudo apt-get update
  sudo apt-get install -y -q software-properties-common
  sudo add-apt-repository -y universe
  sudo add-apt-repository -y ppa:certbot/certbot
  sudo apt-get update
  sudo apt-get install -y -q certbot
EOS
}

install_firewall() {
  sudo bash <<EOS
  apt install -y -q ufw
  systemctl enable ufw
  systemctl restart ufw
  ufw allow ssh
  ufw allow 80/tcp
  ufw allow 8080/tcp
  ufw allow 1337/tcp
  ufw allow 443/tcp
  ufw allow 25/tcp
  ufw allow 587/tcp
  ufw allow 143/tcp
  yes | ufw enable
  ufw reload
  ufw status verbose
EOS
}

fix_system
install_core
log_rotation
install_docker
activate_gcloud
install_ruby
prepare_docker_volumes
install_mailserver
install_firewall
