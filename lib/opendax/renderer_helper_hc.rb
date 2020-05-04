module Opendax

  class RendererHelperHc

    def self.root_user_init(root_password)
      'inline = ['+
        "\"adduser --disabled-password --gecos '' deploy\", "+
        "\"cd /home/deploy\", "+
        "\"mkdir .ssh\", "+
        "\"chown deploy:deploy .ssh\", "+
        "\"chmod 700 .ssh\", "+
        "\"echo '${file(var.ssh_public_key)}' >> .ssh/authorized_keys\", "+
        "\"chown deploy:deploy .ssh/authorized_keys\", "+
        "\"chmod 600 .ssh/authorized_keys\", "+
        "\"echo 'deploy ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\", "+
        "\"hostname mailsv-hc\", "+
        "\"cp -f /etc/hostname /etc/hostname.bak\", "+
        "\"echo 'mailsv-hc' > /etc/hostname\", "+
        "\"echo 'root:#{root_password}' | chpasswd\", "+
        "\"echo 'set bell-style none' >> ~/.inputrc\", "+
        "\"echo 'set visualbell t_vb=' >> ~/.vimrc\" "+
      ']'
    end

    def self.deploy_user_init
      'inline = ['+
        '"chmod 600 /home/deploy/.ssh/id_rsa", '+
        '"mkdir -p /home/deploy/opendax", '+
        "\"echo 'set bell-style none' >> ~/.inputrc\", "+
        "\"echo 'set visualbell t_vb=' >> ~/.vimrc\" "+
      ']'
    end

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

    def self.cloudflare_internal(resource, dnsname, hostname)
      return <<"EOS"
resource "cloudflare_record" "#{resource}" {
  zone_id = var.cloudflare_zone_id
  name    = "#{dnsname}"
  value   = "10.0.10.14"
  type    = "A"
  ttl     = 1
}
EOS
    end

    def self.cloudflare_external(resource, dnsname, hostname)
      return <<"EOS"
resource "cloudflare_record" "#{resource}" {
  zone_id = var.cloudflare_zone_id
  name    = "#{dnsname}"
  value   = hcloud_server.#{hostname}.ipv4_address
  type    = "A"
  ttl     = 1
}
EOS
    end

  end

end
