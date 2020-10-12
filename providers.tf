provider "hcloud" {
  version = "~> 1.20"
  token   = var.hcloud_token
}

provider "aws" {
  version    = "~> 2.70"
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "local" {
  version = "~> 1.4"
}
provider "random" {
  version = "~> 2.3"
}