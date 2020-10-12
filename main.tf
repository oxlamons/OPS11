data "hcloud_ssh_key" "default" {
  name = var.servers.default_ssh_key_name
}

data "aws_route53_zone" "selected" {
  name = var.servers.dns_zone_name
}

resource "hcloud_ssh_key" "personal" {
  name       = var.servers.ssh_key.name
  labels     = var.servers.labels
  public_key = file(var.servers.ssh_key.pub_keyfile)
}

resource "random_password" "password" {
  for_each         = { for server in var.servers.settings : format("%s-%s", server.username, server.prefix) => server }
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "hcloud_server" "server" {
  for_each    = { for server in var.servers.settings : format("%s-%s", server.username, server.prefix) => server }
  name        = each.key
  image       = each.value.image
  server_type = each.value.server_type
  location    = each.value.location
  labels      = var.servers.labels
  ssh_keys = [
    data.hcloud_ssh_key.default.id,
    hcloud_ssh_key.personal.id
  ]
  provisioner "remote-exec" {
    inline = [
      "echo ${var.servers.root_user}:${random_password.password[each.key].result} | chpasswd"
    ]
  }
  connection {
    user        = var.servers.root_user
    type        = "ssh"
    host        = self.ipv4_address
    private_key = file(var.servers.ssh_key.private_keyfile)
    timeout     = "2m"
  }
}

resource "aws_route53_record" "dns_record" {
  depends_on = [hcloud_server.server]
  for_each   = { for server in var.servers.settings : format("%s-%s", server.username, server.prefix) => server }
  zone_id    = data.aws_route53_zone.selected.zone_id
  name       = "${each.key}.${data.aws_route53_zone.selected.name}"
  type       = "A"
  ttl        = "300"
  records    = [hcloud_server.server[each.key].ipv4_address]
}

locals {
  depends_on = [aws_route53_record.dns_record, hcloud_server.server, random_password.password]
  server_names = [for server in var.servers.settings :
    aws_route53_record.dns_record[format("%s-%s", server.username, server.prefix)].name
  ]
  ip_adresses = [for server in var.servers.settings :
    hcloud_server.server[format("%s-%s", server.username, server.prefix)].ipv4_address
  ]
  passwords = [for server in var.servers.settings :
    random_password.password[format("%s-%s", server.username, server.prefix)].result
  ]
}

resource "local_file" "inventory" {
  depends_on = [hcloud_server.server]
  sensitive_content = templatefile("${path.module}/templates/inventory.tmpl", {
    servers     = local.server_names,
    key_path    = var.servers.ssh_key.private_keyfile,
    user        = var.servers.root_user,
    ip_adresses = local.ip_adresses,
    passwords   = local.passwords
  })
  filename        = "${path.module}/output/inventory"
  file_permission = "640"
}

resource "local_file" "passwords" {
  depends_on = [hcloud_server.server]
  sensitive_content = templatefile("${path.module}/templates/passwords.tmpl", {
    servers     = local.server_names,
    ip_adresses = local.ip_adresses,
    passwords   = local.passwords
  })
  filename        = "${path.module}/output/passwords.txt"
  file_permission = "640"
}