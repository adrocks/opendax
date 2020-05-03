module Opendax

  class Util

    def self.show_command_status
      conf = JSON.parse(File.read('./config/render.json'))
      puts "Status: r:c[#{conf['app']}], tf:c[#{conf['cloud']}]"
    end

  end

end