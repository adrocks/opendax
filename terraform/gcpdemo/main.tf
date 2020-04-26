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

resource "google_compute_disk" "opendax" {
  name = "opendax-docker-volumes-${random_id.opendax.hex}"
  type  = "pd-ssd"
  zone  = var.zone
  size  = 60
}

resource "google_compute_attached_disk" "opendax" {
  disk     = google_compute_disk.opendax.id
  instance = google_compute_instance.opendax.id
}

resource "google_compute_instance" "opendax" {
  name         = "${var.instance_name}-${random_id.opendax.hex}"
  machine_type = var.machine_type
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
      nat_ip = google_compute_address.opendax.address
    }
  }

  service_account {
    scopes = ["storage-ro"]
  }

  tags = ["allow-webhook"]

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }

  provisioner "local-exec" {
    command = "rm -rf /tmp/upload && mkdir -p /tmp/upload && rsync -rv --copy-links --safe-links --exclude=terraform ../../ /tmp/upload/"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.ssh_user}/opendax",
    ]

    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
    source      = "/tmp/upload/"
    destination = "/home/${var.ssh_user}/opendax"

    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "remote-exec" {
    script = "../../bin/install.sh"

    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "remote-exec" {
    script = "../../bin/start.sh"

    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }
}

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

resource "google_compute_address" "opendax" {
  name = "opendax-ip-${random_id.opendax.hex}"
}

resource "google_compute_network" "opendax" {
  name = "opendax-network-${random_id.opendax.hex}"
}

provider "cloudflare" {
  version = "~> 2.0"
  api_token  = var.cloudflare_token
}

resource "cloudflare_record" "opendax2" {
  zone_id = var.cloudflare_zone_id
  name    = "opendax2"
  value   = google_compute_address.opendax.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "kibana-opendax2" {
  zone_id = var.cloudflare_zone_id
  name    = "kibana.opendax2"
  value   = google_compute_address.opendax.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "www-opendax2" {
  zone_id = var.cloudflare_zone_id
  name    = "www.opendax2"
  value   = google_compute_address.opendax.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "pma-opendax2" {
  zone_id = var.cloudflare_zone_id
  name    = "pma.opendax2"
  value   = google_compute_address.opendax.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "superset-opendax2" {
  zone_id = var.cloudflare_zone_id
  name    = "superset.opendax2"
  value   = google_compute_address.opendax.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "swagger-barong-opendax2" {
  zone_id = var.cloudflare_zone_id
  name    = "swagger-barong.opendax2"
  value   = google_compute_address.opendax.address
  type    = "A"
  ttl     = 1
}
resource "cloudflare_record" "swagger-opendax2" {
  zone_id = var.cloudflare_zone_id
  name    = "swagger.opendax2"
  value   = google_compute_address.opendax.address
  type    = "A"
  ttl     = 1
}