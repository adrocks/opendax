#!/bin/bash -x

# Ubuntu 18.04 LTS minimal

COMPOSE_VERSION="1.23.2"
COMPOSE_URL="https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)"

install_opendax() {
  sudo -u deploy bash <<EOS
  cd /home/deploy
  source /home/deploy/.rvm/scripts/rvm
  rvm install --quiet-curl 2.6.5
  rvm use --default 2.6.5
  gem install bundler


  cd opendax

  bundle install --path vendor/bundle
  bundle exec rake render:config
  
  # Mailserver
  bundle exec rake service:mailserver  
  sleep 5

  # Mailsetup
  source bin/setup_mailserver.sh email add postmaster@plusqo.com xUbIt8eTTOwkn830qxC1ybK0TxyR7LfJ
  sleep 5
  source bin/setup_mailserver.sh email add one@plusqo.com xUbIt8eTTOwkn830qxC1ybK0TxyR7LfJ
  sleep 5
  source bin/setup_mailserver.sh email add two@plusqo.com xUbIt8eTTOwkn830qxC1ybK0TxyR7LfJ
  sleep 5
  source bin/setup_mailserver.sh email add three@plusqo.com xUbIt8eTTOwkn830qxC1ybK0TxyR7LfJ
  sleep 5
  source bin/setup_mailserver.sh alias add three@plusqo.com tech@plusqo.com chupi@kih.biglobe.ne.jp
  sleep 5

  #chmod +x bin/install_webhook
  #./bin/install_webhook
EOS
}

install_opendax
