#!/bin/bash -x

start_opendax() {
  sudo -u deploy bash <<EOS
  cd /home/deploy
  source /home/deploy/.rvm/scripts/rvm
  rvm install --quiet-curl 2.6.5
  rvm use --default 2.6.5
  gem install bundler
  cd opendax
  bundle install --path vendor/bundle
  bundle exec rake render:config
  bundle exec rake service:mailserver  
  sleep 10
  source bin/setup_mailserver.sh email add postmaster@plusqo.com xUbIt8eTTOwkn830qxC1ybK0TxyR7LfJ
  sleep 5
  source bin/setup_mailserver.sh email add one@plusqo.com xUbIt8eTTOwkn830qxC1ybK0TxyR7LfJ
  sleep 5
  source bin/setup_mailserver.sh email add two@plusqo.com xUbIt8eTTOwkn830qxC1ybK0TxyR7LfJ
  sleep 5
  source bin/setup_mailserver.sh email add three@plusqo.com xUbIt8eTTOwkn830qxC1ybK0TxyR7LfJ
  sleep 5
  source bin/setup_mailserver.sh alias add tech@plusqo.com chupi@kih.biglobe.ne.jp
  sleep 5
  bundle exec rake service:mailserver[stop]
  bundle exec rake service:mailserver
EOS
}

start_opendax
