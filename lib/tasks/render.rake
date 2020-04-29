
require_relative '../opendax/renderer'

namespace :render do
  desc 'Render configuration and compose files and keys'
  task :config do
    # Must be chown $USER and chmod 666 
    unless (File.exist?("config/bitcoin.conf")) then
      sh "touch config/bitcoin.conf"
    end
    sh "sudo chown #{ENV['USER']} config/bitcoin.conf"
    renderer = Opendax::Renderer.new
    renderer.render_keys
    renderer.render
  end

  desc 'Select app.yml for render:config [local|prd|stg|gcpdemo]'
  task :select, [:app] do |_, args|
    args.with_defaults(:app => 'local')
    Dir.chdir('config') {
      if (args.app == 'local' || args.app == 'sample' || args.app == 'prd' ||
        args.app == 'stg' || args.app == 'gcpdemo') then
        FileUtils.symlink("app.yml.d/#{args.app}.app.yml", "app.yml", {:force => true})
        puts "Selected: #{args.app}"
      else
        puts "Error: Specify a param: render:select[local|prd|stg|gcpdemo]"
      end
    }
  end
end
