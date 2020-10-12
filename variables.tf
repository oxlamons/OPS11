#
# Secrets/tokens for API access
#
variable "hcloud_token" {
  type    = string
  default = "V"
}
variable "" {
  type    = string
  default = "C"
}
variable "aws_secret_key" {
  type    = string
  default = "1"
}
#
# Tunables for servers, naming convention: username-prefix
# refer to https://docs.hetzner.cloud/ for suitable values
# ssh private key shouldn't be password protected

variable "servers" {
  type = object({
    settings = list(object({

      username    = username1
      prefix      = "ansible"
      location    = "fsn1"
      image       = "ubuntu-18.04"
      server_type = "cx11"
      },
      { username    = "username2"
        prefix      = "web1"
        location    = "fsn1"
        image       = "ubuntu-18.04"
        server_type = "cx11"
      },
      {
        username    = "username2"
        prefix      = "web2"
        location    = "fsn1"
        image       = "centos-8"
        server_type = "cx11"
    }))
    root_user            = "root"
    default_ssh_key_name = "REBRAIN.SSH.PUB.KEY"
    dns_zone_name        = "devops.srwx.net."
    labels = {
      module = "devops",
      email  = "oxlamons_at_domain_com"
    }
    ssh_key = object({
      name            = "username_key"
      pub_keyfile     = "~/.ssh/id_rsa.pub"
      private_keyfile = "~/.ssh/id_rsa"
    })
  })
}
