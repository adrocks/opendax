namespace :email do

  top_level = self

  desc 'Init mailboxes & aliases on seed yml(WARN: CLEAR&recreate)'
  task :init do
    config_path =File.expand_path('./config/mailsv')
    ENV['CONFIG_PATH']=config_path
    sh "rm -f ./config/mailsv/postfix-accounts.cf"
    sh "rm -f ./config/mailsv/postfix-virtual.cf"
    sh "chmod +x bin/setup_mailsv.sh"
    @config['mailsv']['emails'].each { |r|
      sh "bin/setup_mailsv.sh email add #{r['address']} #{r['password']}"
    }
    @config['mailsv']['aliases'].each { |r|
      sh  "bin/setup_mailsv.sh alias add #{r['address']} #{r['to']}"
    }
    sh "bin/setup_mailsv.sh email list"
    sh "bin/setup_mailsv.sh alias list"
  end

end
