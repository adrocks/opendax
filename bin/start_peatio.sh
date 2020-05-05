#!/bin/bash -x

#bundle exec rake wallet:create['deposit','http://127.0.0.1:8545','changeme']
#bundle exec rake wallet:create['hot','http://127.0.0.1:8545','changeme']
#bundle exec rake wallet:create['warm','http://127.0.0.1:8545','changeme']

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
  bundle exec rake service:logagent
EOS
}

start_opendax
