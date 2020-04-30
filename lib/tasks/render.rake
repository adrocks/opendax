
require_relative '../opendax/renderer'

namespace :render do

  top_level = self

  using Module.new {
    refine(top_level.singleton_class) do
      def check_app
        Dir.chdir('config') do
          link_to = File.readlink('app.yml')
          app = File.basename(link_to).split('.')[0]
          if (app == "sample") then
            puts "You have to prepare config/app.yml.d/local.app.yml"
            puts "And 'bundle exec rake render:select[local]'"
            return false
          end
          return true
          rescue
            #puts "Can't readlink: config/app.yml."
            return true
        end
      end
    end
  } 

  desc 'Render configuration and compose files and keys'
  task :config do
    next if (!check_app)
    # Must be chown $USER
    unless (File.exist?("config/bitcoin.conf")) then
      sh "touch config/bitcoin.conf"
    end
    sh "sudo chown #{ENV['USER']} config/bitcoin.conf"
    renderer = Opendax::Renderer.new
    renderer.render_keys
    renderer.render
  end

  desc 'Select app.yml for render:config [local|base|prd|stg|gcpdemo]'
  task :select, [:app] do |_, args|
    args.with_defaults(:app => 'local')
    Dir.chdir('config') {
      if (args.app == 'local' || args.app == 'sample' || args.app == 'prd' ||
        args.app == 'stg' || args.app == 'gcpdemo'|| args.app == 'base') then
        FileUtils.symlink("app.yml.d/#{args.app}.app.yml", "app.yml", {:force => true})
        puts "Selected: #{args.app}"
      else
        puts "Error: Specify a param: render:select[local|base|prd|stg|gcpdemo]"
      end
    }
  end
end
