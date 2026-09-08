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
