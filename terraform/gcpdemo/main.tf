################################################################################
# App: gcpdemo (staging spec.)
# * Peatio system demonstration on Google Cloud Platform
# * Staging spec (testnet and valut not used)
# * https://www.gcpdemo.plusqo.com/

################################################################################
# Google Cloud Platform

################ Common

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

################ Peatio

resource "google_compute_instance" "peatio" {
  name         = "peatio-${random_id.opendax.hex}"
  machine_type = "n1-standard-2"
  zone         = var.zone
  allow_stopping_for_update = true
  lifecycle {
    ignore_changes = [attached_disk]
  }
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
      nat_ip = google_compute_address.peatio.address
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
    script = "../../bin/install.sh"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "remote-exec" {
    script = "../../bin/start.sh"
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "deploy"
      private_key = file(var.ssh_private_key)
    }
  }
}

resource "google_compute_address" "peatio" {
  name = "opendax-ip-${random_id.opendax.hex}"
}
resource "google_compute_disk" "peatio" {
  name = "peatio-docker-volumes-${random_id.opendax.hex}"
  type  = "pd-ssd"
  zone  = var.zone
  size  = 60
}
resource "google_compute_attached_disk" "peatio" {
  disk     = google_compute_disk.peatio.id
  instance = google_compute_instance.peatio.id
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
}

################################################################################
# Cloudflare

################ Common

provider "cloudflare" {
  version = "~> 2.0"
  api_token  = file(var.cloudflare_token)
}

################ Peatio

resource "cloudflare_record" "peatio" {
  zone_id = var.cloudflare_zone_id
  name    = "gcpdemo"
  value   = google_compute_address.peatio.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "kibana-peatio" {
  zone_id = var.cloudflare_zone_id
  name    = "kibana.gcpdemo"
  value   = google_compute_address.peatio.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "www-peatio" {
  zone_id = var.cloudflare_zone_id
  name    = "www.gcpdemo"
  value   = google_compute_address.peatio.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "pma-peatio" {
  zone_id = var.cloudflare_zone_id
  name    = "pma.gcpdemo"
  value   = google_compute_address.peatio.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "superset-peatio" {
  zone_id = var.cloudflare_zone_id
  name    = "superset.gcpdemo"
  value   = google_compute_address.peatio.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "swagger-barong-peatio" {
  zone_id = var.cloudflare_zone_id
  name    = "swagger-barong.gcpdemo"
  value   = google_compute_address.peatio.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "swagger-peatio" {
  zone_id = var.cloudflare_zone_id
  name    = "swagger.gcpdemo"
  value   = google_compute_address.peatio.address
  type    = "A"
  ttl     = 1
}

################################################################################
