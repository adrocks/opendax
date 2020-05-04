module Opendax

  class RendererHelperHc

    def self.connstr(user)
      return <<"EOS"
      connection {
        host        = self.ipv4_address
        type        = "ssh"
        user        = "#{user}"
        private_key = file(var.ssh_private_key)
      }
EOS
    end

    def self.provisioner_local_exec(command)
      return <<"EOS"
    provisioner "local-exec" {
      command = #{command}
    }      
EOS
    end

    def self.provisioner_remote_exec(user, body)
      connstr = self::connstr(user)
      return <<"EOS"
    provisioner "remote-exec" {
      #{body}
      #{connstr}
    }
EOS
    end

    def self.provisioner_file(user, src, dest)
      connstr = self::connstr(user)
      return <<"EOS"
    provisioner "file" {
      source = #{src}
      destination = #{dest}
      #{connstr}
    }
EOS
    end

  end

end
