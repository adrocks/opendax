
require_relative '../opendax/renderer'

namespace :render do

  desc 'Render configuration and compose files and keys'
  task :config do
    # Must be chown $USER beforehand becuase can't overwrite 
    unless (File.exist?("config/bitcoin.conf")) then
      sh "touch config/bitcoin.conf"
    end
    sh "sudo chown #{ENV['USER']} config/bitcoin.conf"
    renderer = Opendax::Renderer.new
    renderer.render_keys
    renderer.render
    conf = JSON.parse(File.read('./config/render.json'))
    puts "Render target app: #{conf['app']}"
  end

end
