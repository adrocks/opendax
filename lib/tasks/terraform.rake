namespace :terraform do

  top_level = self

  using Module.new {
    refine(top_level.singleton_class) do
      def linked_app
        Dir.chdir('config') do
          link_to = File.readlink('app.yml')
          app = File.basename(link_to).split('.')[0]
          if (app != "prd" && app != "stg1" && app != "stg2" &&
              app != "stg3" && app != "base" ) then
              puts "You have to do 'bundle exec rake render:select[prd|stg1-3|base]'"
              return nil
          end
          app
          rescue
            puts "Can't readlink: config/app.yml."
        end
      end
      def show_afterwards
        puts "Please exec 'bundle exec rake render:select[local]' if needed."
      end
    end
  } 

  desc 'Initialize the Terraform configuration'
  task :init do
    app = linked_app
    next unless app
    puts "terraform:init: #{app}"
    Dir.chdir("terraform/#{app}") {
      cmd = "terraform init"
      sh cmd do |ok, status|
      end
    }
  end

  desc 'Apply the Terraform configuration'
  task :apply do
    app = linked_app
    next unless app
    puts "terraform:apply: #{app}"
    Rake::Task["render:config"].invoke
    Dir.chdir("terraform/#{app}") {
      sh 'terraform apply' do |ok, status|
      end
    }
    show_afterwards
  end

  desc 'Plan the Terraform configuration'
  task :plan do
    app = linked_app
    next unless app
    puts "terraform:plan: #{app}"
    Rake::Task["render:config"].invoke
    Dir.chdir("terraform/#{app}") {
      sh 'terraform plan' do |ok, status|
      end
    }
    show_afterwards
  end

  desc 'Destroy the Terraform infrastructure'
  task :destroy do
    app = linked_app
    next unless app
    puts "terraform:destroy: #{app}"
    Rake::Task["render:config"].invoke
    Dir.chdir("terraform/#{app}") {
      sh 'terraform destroy' do |ok, status|
      end
    }
    show_afterwards
  end

  desc 'Show the Terraform infrastructure'
  task :show do
    app = linked_app
    next unless app
    puts "terraform:show: #{app}"
    Dir.chdir("terraform/#{app}") {
      sh 'terraform show' do |ok, status|
      end
    }
    show_afterwards
  end
end
