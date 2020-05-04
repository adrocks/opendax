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
