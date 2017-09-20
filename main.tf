provider "google" {
  version     = "~> 0.1"
  credentials = "${file("account.json")}"
  project     = "${var.gcp_project}"
  region      = "us-west1"
}

resource "google_compute_network" "nomad" {
  name                    = "nomad"
  auto_create_subnetworks = "true"
}

data "external" "myip" {
  program = ["bash", "${path.module}/myip.sh"]
}

resource "google_compute_firewall" "nomad" {
  name    = "nomad"
  network = "${google_compute_network.nomad.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${data.external.myip.result["myip"]}/32"]
}

resource "google_compute_instance_template" "nomad" {
  name_prefix  = "nomadit-"
  machine_type = "n1-standard-2"

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-1604-lts"
    boot         = true
  }

  network_interface {
    network       = "nomad"
    access_config = {}
  }

  metadata_startup_script = "${file("startup.sh")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "nomad" {
  name               = "nomad"
  instance_template  = "${google_compute_instance_template.nomad.self_link}"
  base_instance_name = "nomadig"
  zone               = "us-west1-b"
  target_size        = "3"
}

data "google_compute_instance_group" "nomad" {
  name = "${element(split("/", google_compute_instance_group_manager.nomad.instance_group.name), 10)}"
  zone = "us-west1-b"
}

output "instances" {
  value = ["${data.google_compute_instance_group.nomad.instances}"]
}
