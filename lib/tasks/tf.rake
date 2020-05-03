require_relative '../opendax/util'

namespace :tf do

  desc 'Set (c)loud platform for Terraform [gcp|hc]'
  task :c, [:kind] do |_, args|
    conf = JSON.parse(File.read('./config/render.json'))
    if (args.kind.nil? || (args.kind != 'gcp' && args.kind != 'hc')) then
      puts "Specify paramter [gcp|hc]."
      Opendax::Util::show_command_status
      next
    end
    conf['cloud'] = args.kind
    File.write('./config/render.json', conf.to_json)
    puts "Set cloud: #{conf['cloud']}"
    Opendax::Util::show_command_status
  end

  desc 'Initialize the Terraform configuration'
  task :init do
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      sh "terraform init" do |ok, status|
      end
    }
  end

  desc 'Apply the Terraform configuration'
  task :apply do
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      sh "terraform apply" do |ok, status|
      end
    }
  end

  desc 'Plan the Terraform configuration'
  task :plan do
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      sh "terraform plan" do |ok, status|
      end
    }
  end

  desc 'Destroy the Terraform infrastructure'
  task :destroy do
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      sh "terraform destroy" do |ok, status|
      end
    }
  end

  desc 'Show the Terraform infrastructure'
  task :show do
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      sh "terraform show" do |ok, status|
      end
    }
  end
end
