require 'yaml'
require 'base64'
require 'erb'
require "digest"

CONFIG_PATH = 'config/app.yml'.freeze
UTILS_PATH = 'config/utils.yml'.freeze
DEPLOY_PATH = 'config/deploy.yml'.freeze

######## START First time after git clone ########

#### Generate master.key
unless (File.exist?("config/master.key")) then
  puts "Welcome. It seems you are using this repository for the first time."
  puts " Making master.key for the system."
  print "  Please input master password (get from admin):"
  input = STDIN.gets.chomp
  sha256 = Digest::SHA256.new
  sha256.update(input)
  File.write('config/master.key', sha256.hexdigest)
  puts "[Important] First time notice)"
  puts "Now you also have to execute 'gcloud auth login',"
  puts "and get a proper GCP credential for the system."
  print "[OK: Enter]"
  STDIN.gets
else
  # Check master key
  hash =Digest::SHA256.hexdigest(File.read('config/master.key'))
  if (hash != '092f62296f5056e38ee95615df792506ab8a11a3db86a20cc841be0766b71255') then
    puts "Incorrect config/master.key. Erase it and retry by 'bundle exec rake -T'"
    exit
  end
end

#### Prepare sample yml.

# config/app.yml is the important file in the system,
# but is not contained in git,
# so, after clone, we have to make symlink to config/app.yml.d/sample.app.yml

Dir.chdir('config') do
  # Only when local
  # (when remote, app.yml is not symlink by terraform transfer)
  if (ENV['USER'] != 'deploy') then
    File.readlink("app.yml")
  end
rescue
  # config/app.yml symlink not found = seems first time
  FileUtils.symlink("app.yml.d/sample.app.yml", "app.yml", {:force => true})
  puts "Rakefile: Using sample.app.yml"
end

# first time, copy from sample stuff
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

######## END First time after git clone ########

# Special macro
@config = YAML.load_file(CONFIG_PATH)
@config['app']['docker_volumes_path'].gsub!(/__USER__/, ENV['USER'])

@utils = YAML.load_file(UTILS_PATH)
@deploy = YAML.load_file(DEPLOY_PATH)

# Add your own tasks in files placed in lib/tasks ending in .rake
Dir.glob('lib/tasks/*.rake').each do |task|
  load task
end