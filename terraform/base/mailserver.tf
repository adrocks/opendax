################################################################################
# App: gcpdemo (staging spec.)
# * Peatio system demonstration on Google Cloud Platform
# * Staging spec (testnet and valut not used)
# * https://www.gcpdemo.plusqo.com/

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
output "opendax_mailserver_external_ip" {
  value = "${google_compute_address.mailserver.address}"
}
output "opendax_mailserver_internal_ip" {
  value = "${google_compute_instance.mailserver.network_interface[0].network_ip}"
}

################ Mailserver

resource "google_compute_instance" "mailserver" {
  name         = "mailserver-${random_id.opendax.hex}"
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
      nat_ip = google_compute_address.mailserver.address
    }
  }
  service_account {
    scopes = ["storage-ro"]
  }
  tags = ["allow-webhook"]
  metadata = {
    sshKeys = "deploy:${file(var.ssh_public_key)}"
  }
  provisioner "local-exec" {
    command = "rm -rf /tmp/upload && mkdir -p /tmp/upload && rsync -rv --copy-links --safe-links --exclude=terraform ../../ /tmp/upload/"
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/deploy/opendax",
    ]
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
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
  provisioner "remote-exec" {
    script = "../../bin/install_mailserver.sh"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "remote-exec" {
    script = "../../bin/start_mailserver.sh"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
}

resource "google_compute_address" "mailserver" {
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

################ Mailserver

resource "cloudflare_record" "mailserver" {
  zone_id = var.cloudflare_zone_id
  name    = "mailserver"
  value   = google_compute_address.mailserver.address
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "internal-mailserver" {
  zone_id = var.cloudflare_zone_id
  name    = "mailserver.internal"
  value   = google_compute_instance.mailserver.network_interface[0].network_ip
  type    = "A"
  ttl     = 1
}

################################################################################
