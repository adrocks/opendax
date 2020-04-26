variable "hcloud_token" {
  type = string
  default = var.hcloud_token
}
provider "hcloud" {
  version = "~> 1.16"
  token = var.hcloud_token
}

data "hcloud_ssh_key" "opendax" {
  fingerprint = var.hcloud_ssh_fingerprint
}

resource "hcloud_network" "opendax" {
  name = "opendax"
  ip_range = "10.0.1.0/24"
}

resource "hcloud_server" "opendax" {
  name = "opendax"
  image = "debian-10"
  server_type = "cx31"
  #location = "fsn1"
  datacenter = "fsn1-dc14"
  ssh_keys = ["${data.hcloud_ssh_key.opendax.id}"]
  provisioner "local-exec" {
    command = "rm -rf /tmp/upload && mkdir -p /tmp/upload && rsync -rv --copy-links --safe-links --exclude=terraform ../../ /tmp/upload/"
  }
  provisioner "remote-exec" {
    inline = [
      "adduser --disabled-password --gecos '' deploy",
      "cd /home/deploy",
      "mkdir .ssh",
      "chown deploy:deploy .ssh",
      "chmod 700 .ssh",
      "echo '${file(var.ssh_public_key)}' >> .ssh/authorized_keys",
      "chown deploy:deploy .ssh/authorized_keys",
      "chmod 600 .ssh/authorized_keys",
      "echo 'deploy ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers",
    ]
    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/deploy/opendax",
    ]
    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
    source      = "/tmp/upload/"
    destination = "/home/deploy/opendax"

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "remote-exec" {
    script = "../../bin/install.sh"

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "remote-exec" {
    script = "../../bin/start.sh"

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
}

