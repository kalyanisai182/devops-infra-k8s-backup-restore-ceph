terraform {
  backend "s3" {
    key = "shared/terraform.tfstate"
  }
}
