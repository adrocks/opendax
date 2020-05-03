
require_relative '../opendax/renderer'

namespace :r do

  top_level = self

  using Module.new {
    refine(top_level.singleton_class) do
      def check_app(app)
        if (app == 'local' || app == 'sample' || app == 'prd' ||
          app == 'stg1' || app == 'stg2' || app == 'stg3' ||
          app == 'base') then
          return true
        end
        puts "Error: Specify a param: [local|base|prd|stg1-3]"
        false
      end
    end
  } 

  desc '(R)ender:(c)onfig with [local|base|prd|stg1-3]'
  task :c, [:app] do |_, args|
    if (args.app.nil?) then
      puts "Error: no parameter specified."
      next
    end
    next unless (check_app(args.app))
    conf = {}
    conf['app'] = args.app
    File.write('./config/render.json', conf.to_json)
    Rake::Task["render:config"].invoke
  end

  desc '(R)ender:(s)how render:config target app'
  task :s do
    conf = JSON.parse(File.read('./config/render.json'))
    puts "Current render target app is: #{conf['app']}"
  end

end
