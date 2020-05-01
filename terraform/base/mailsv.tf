################################################################################
# Google Cloud Platform

################ Common

# Storing tfstate into GCP bucket
# must be inited by terraform init command args.
# and you have to create the bucket manually beforehand.
terraform {
  backend "gcs" {
  }
}

provider "google" {
  version = "~> 3.18"
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}
provider "random" {
  version = "~> 2.2"
}
resource "random_id" "opendax" {
  byte_length = 2
}

################ Output

output "opendax_network_name" {
  value = "${google_compute_network.opendax.name}"
}
output "opendax_mailsv_external_ip" {
  value = "${google_compute_address.mailsv.address}"
}
output "opendax_mailsv_internal_ip" {
  value = "${google_compute_instance.mailsv.network_interface[0].network_ip}"
}

################ mailsv

resource "google_compute_instance" "mailsv" {
  name         = "mailsv-${random_id.opendax.hex}"
  machine_type = "n1-standard-2"
  zone         = var.zone
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = var.image
      type  = "pd-ssd"
      size  = 30
    }
  }
  network_interface {
    network = google_compute_network.opendax.name
    access_config {
      nat_ip = google_compute_address.mailsv.address
    }
  }
  service_account {
    scopes = ["storage-ro"]
  }
  tags = ["allow-webhook"]
  metadata = {
    sshKeys = "deploy:${file(var.ssh_public_key)}"
  }
  provisioner "file" {
    source      = var.ssh_private_key
    destination = "/home/deploy/.ssh/id_rsa"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/deploy/.ssh/id_rsa",
      "mkdir -p /home/deploy/opendax",
    ]
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "local-exec" {
    command = "rm -rf /tmp/upload && mkdir -p /tmp/upload && rsync -rv --copy-links --safe-links --exclude=terraform ../../ /tmp/upload/"
  }
  provisioner "file" {
    source      = "/tmp/upload/"
    destination = "/home/deploy/opendax"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "file" {
    source      = var.ssh_private_key
    destination = "/home/deploy/.ssh/id_rsa"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "remote-exec" {
    script = "../../bin/install_mailsv.sh"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "remote-exec" {
    script = "../../bin/start_mailsv.sh"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
}

resource "google_compute_address" "mailsv" {
  name = "opendax-ip-${random_id.opendax.hex}"
}

################ Shared resources

resource "google_compute_firewall" "opendax" {
  name    = "opendax-firewall-${random_id.opendax.hex}"
  network = google_compute_network.opendax.name
  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1337", "443", "22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["allow-webhook"]
}
resource "google_compute_network" "opendax" {
  name = "opendax-network-${random_id.opendax.hex}"
  auto_create_subnetworks = true
}

################################################################################
# Cloudflare

################ Common

provider "cloudflare" {
  version = "~> 2.0"
  api_token  = file(var.cloudflare_token)
}

################ mailsv

resource "cloudflare_record" "mailsv" {
  zone_id = var.cloudflare_zone_id
  name    = "mailsv"
  value   = google_compute_address.mailsv.address
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "internal-mailsv" {
  zone_id = var.cloudflare_zone_id
  name    = "mailsv.internal"
  value   = google_compute_instance.mailsv.network_interface[0].network_ip
  type    = "A"
  ttl     = 1
}

################################################################################
