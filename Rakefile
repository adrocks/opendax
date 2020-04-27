require 'yaml'
require 'base64'
require 'erb'

CONFIG_PATH = 'config/app.yml'.freeze
UTILS_PATH = 'config/utils.yml'.freeze
DEPLOY_PATH = 'config/deploy.yml'.freeze

#### First time after clone
#### Copy sample yml.

Dir.chdir('config') do
  File.readlink("app.yml")
rescue
  # config/app.yml symlink not found = seems first time
  FileUtils.symlink("app.yml.d/sample.app.yml", "app.yml", {:force => true})
  puts "Rakefile: Using sample.app.yml"
end

Dir.chdir('config') do
  unless (File.exist?("deploy.yml")) then
    FileUtils.copy("sample.deploy.yml", "deploy.yml")
    puts "Rakefile: Using sample.deploy.yml"
  end
  unless (File.exist?("utils.yml")) then
    FileUtils.copy("sample.utils.yml", "utils.yml")
    puts "Rakefile: Using sample.utils.yml"
  end
end

####

@config = YAML.load_file(CONFIG_PATH)
@utils = YAML.load_file(UTILS_PATH)

# Add your own tasks in files placed in lib/tasks ending in .rake
Dir.glob('lib/tasks/*.rake').each do |task|
  load task
end