include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/compute-engine"
}

inputs = {
  instance_name = "cmr-lab-vm"
  machine_type  = "e2-micro"
  zone          = "europe-west1-b"
  image         = "debian-cloud/debian-12"
  environment   = "lab"
}
