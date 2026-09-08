#!/bin/bash

set -e

mkdir -p lab/compute-engine
mkdir -p nl/compute-engine
mkdir -p modules/compute-engine

touch atlantis.yaml
touch README.md
touch .gitignore

#################################################
# LAB
#################################################

cat > lab/terragrunt.hcl <<'EOF'
locals {
  project_id = "vf-grp-aib-dev-cmr-pe-lab"
  region     = "europe-west1"
  zone       = "europe-west1-b"
}

remote_state {
  backend = "gcs"

  config = {
    bucket = "vf-grp-aib-dev-cmr-pe-lab-tfstate"
    prefix = "${path_relative_to_include()}"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"

  contents = <<PROVIDER
provider "google" {
  project = "${local.project_id}"
  region  = "${local.region}"
  zone    = "${local.zone}"
}
PROVIDER
}
EOF

#################################################
# NL
#################################################

cat > nl/terragrunt.hcl <<'EOF'
locals {
  project_id = "vf-grp-aib-dev-cmr-pe-nl"
  region     = "europe-west1"
  zone       = "europe-west1-b"
}

remote_state {
  backend = "gcs"

  config = {
    bucket = "vf-grp-aib-dev-cmr-pe-nl-tfstate"
    prefix = "${path_relative_to_include()}"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"

  contents = <<PROVIDER
provider "google" {
  project = "${local.project_id}"
  region  = "${local.region}"
  zone    = "${local.zone}"
}
PROVIDER
}
EOF

#################################################
# LAB COMPUTE
#################################################

cat > lab/compute-engine/terragrunt.hcl <<'EOF'
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
EOF

#################################################
# NL COMPUTE
#################################################

cat > nl/compute-engine/terragrunt.hcl <<'EOF'
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/compute-engine"
}

inputs = {
  instance_name = "cmr-nl-vm"
  machine_type  = "e2-micro"
  zone          = "europe-west1-b"
  image         = "debian-cloud/debian-12"
  environment   = "nl"
}
EOF

#################################################
# MODULE
#################################################

cat > modules/compute-engine/main.tf <<'EOF'
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
EOF

cat > modules/compute-engine/variables.tf <<'EOF'
variable "instance_name" {}
variable "machine_type" {}
variable "zone" {}
variable "image" {}
variable "environment" {}
EOF

cat > modules/compute-engine/outputs.tf <<'EOF'
output "instance_name" {
  value = google_compute_instance.vm.name
}
EOF

#################################################
# ATLANTIS
#################################################

cat > atlantis.yaml <<'EOF'
version: 3

projects:
- name: lab-compute
  dir: lab/compute-engine
  workflow: terragrunt
  autoplan:
    enabled: true

- name: nl-compute
  dir: nl/compute-engine
  workflow: terragrunt
  autoplan:
    enabled: true

workflows:
  terragrunt:
    plan:
      steps:
      - run: terragrunt init
      - run: terragrunt plan -out=$PLANFILE

    apply:
      steps:
      - run: terragrunt apply $PLANFILE
EOF

echo "POC Repository Created"
