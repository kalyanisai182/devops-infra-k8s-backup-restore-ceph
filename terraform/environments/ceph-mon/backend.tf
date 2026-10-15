terraform {
  backend "s3" {
    key = "ceph-mon/terraform.tfstate"
  }
}
