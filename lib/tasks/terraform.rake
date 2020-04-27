namespace :terraform do

  top_level = self

  using Module.new {
    refine(top_level.singleton_class) do
      def linked_app
        Dir.chdir('config') do
          link_to = File.readlink('app.yml')
          app = File.basename(link_to).split('.')[0]
          if (app != "prd" && app != "stg" &&
              app != "gcpdemo") then
              puts "You have to do 'bundle exec rake render:select[prd|stg|gcpdemo]'"
              return nil
          end
          app
          rescue
            puts "Can't readlink: config/app.yml."
            puts "Maybe you have to put local.app.yml into config/app.yml.d/"
            puts "(Customize based on config/app.yml.d/sample.app.yml)"
            puts "And then exec, 'bundle exec rake render:select[local]' first."
        end
      end
      def show_afterwards
        puts "Please exec 'bundle exec rake render:select[local]' if needed."
      end
    end
  } 

  desc 'Initialize the Terraform configuration'
  task :init do
    next unless linked_app
    puts "terraform:init: #{linked_app}"
    Dir.chdir("terraform/#{linked_app}") { sh 'terraform init' }
    show_afterwards
  end

  desc 'Apply the Terraform configuration'
  task :apply do
    next unless linked_app
    puts "terraform:apply: #{linked_app}"
    Rake::Task["render:config"].invoke
    Dir.chdir("terraform/#{linked_app}") { sh 'terraform apply' }
    show_afterwards
  end

  desc 'Plan the Terraform configuration'
  task :plan do
    next unless linked_app
    puts "terraform:plan: #{linked_app}"
    Rake::Task["render:config"].invoke
    Dir.chdir("terraform/#{linked_app}") { sh 'terraform plan' }
    show_afterwards
  end

  desc 'Destroy the Terraform infrastructure'
  task :destroy do
    next unless linked_app
    puts "terraform:destroy: #{linked_app}"
    Rake::Task["render:config"].invoke
    Dir.chdir("terraform/#{linked_app}") { sh 'terraform destroy' }
    show_afterwards
  end
end
