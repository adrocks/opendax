require 'yaml'
require 'base64'
require 'erb'

CONFIG_PATH = 'config/app.yml'.freeze
UTILS_PATH = 'config/utils.yml'.freeze
DEPLOY_PATH = 'config/deploy.yml'.freeze

Dir.chdir('config') do
  File.readlink(CONFIG_PATH)
rescue
  # First time after clone
  # config/app.yml symlink not found = seems first time
  FileUtils.symlink("app.yml.d/sample.app.yml", "app.yml", {:force => true})
  puts "Rakefile: Using sample.app.yml"
end

@config = YAML.load_file(CONFIG_PATH)
@utils = YAML.load_file(UTILS_PATH)

# Add your own tasks in files placed in lib/tasks ending in .rake
Dir.glob('lib/tasks/*.rake').each do |task|
  load task
end