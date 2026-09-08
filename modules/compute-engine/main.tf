resource "google_compute_instance" "vm" {

  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = 20
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  labels = {
    environment = var.environment
  }
}
