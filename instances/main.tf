#######################################
# Providers                           #
#######################################

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}"
}

provider "cloudflare" {
  version = "~> 2.0"
  email   = "${var.cloudflare_email}"
  api_key = "${var.cloudflare_api_key}"
}

#######################################
# Local Vars                          #
#######################################

# Local Variables
locals {
#  instances_init_scripts = data.template_file.init.*.rendered
  base_instances_ipv4 = hcloud_server.client-base.*.ipv4_address
  vscode_instances_ipv4 = hcloud_server.client-vscode.*.ipv4_address
#  instances_pw = random_password.password.*.result
}

#######################################
# Resources                           #
#######################################

# Add a "A" record to the domain for Client Nodes
resource "cloudflare_record" "cf_dns_client_base" {
  count = "${var.base_instances_count}"
  zone_id = "${var.cloudflare_zone_id}"
  name    = "${var.client-base-subdomain_prefix}-${count.index}.${var.serversubdomain}"
  # set IP's from the local var (list)
  value = "${element(local.base_instances_ipv4, count.index)}"
  type    = "A"
  ttl     = 3600
}

# Add a "A" record to the domain for Client VS Code Nodes
resource "cloudflare_record" "cf_dns_client_vscode" {
  count = "${var.vscode_instances_count}"
  zone_id = "${var.cloudflare_zone_id}"
  name    = "${var.client-vscode-subdomain_prefix}-${count.index}.${var.serversubdomain}"
  # set IP's from the local var (list)
  value = "${element(local.vscode_instances_ipv4, count.index)}"
  type    = "A"
  ttl     = 3600
}

# Add a "A" record for the Server Node
resource "cloudflare_record" "cf_dns_server" {
  zone_id = "${var.cloudflare_zone_id}"
  name    = "${var.serversubdomain}"
  # set IP's from the local var (list)
  value = "${hcloud_server.server.ipv4_address}"
  type    = "A"
  ttl     = 3600
}

# Add a "A" record Wildcard subdomains Server Node
resource "cloudflare_record" "cf_wc_dns_server" {
  zone_id = "${var.cloudflare_zone_id}"
  name    = "*.${var.serversubdomain}"
  # set IP's from the local var (list)
  value = "${hcloud_server.server.ipv4_address}"
  type    = "A"
  ttl     = 3600
}

# Create a User Linux only Server
resource "hcloud_server" "client-base" {
  count = "${var.base_instances_count}"
  name = "${var.client-base-subdomain_prefix}-${count.index}.${var.serversubdomain}.${var.instances_domain}"
  image = "ubuntu-18.04"
  server_type = "cx11"
  location = "nbg1"
  ssh_keys = "${var.ssh_keys}"
  # user_data = "${file("${path.module}/init.tpl")}"
  user_data = "${data.template_file.init_base.rendered}"
}

# Create a User VS-Code machine
resource "hcloud_server" "client-vscode" {
  count = "${var.vscode_instances_count}"
  name = "${var.client-vscode-subdomain_prefix}-${count.index}.${var.serversubdomain}.${var.instances_domain}"
  image = "ubuntu-18.04"
  server_type = "cx11"
  location = "nbg1"
  ssh_keys = "${var.ssh_keys}"
  # user_data = "${file("${path.module}/init.tpl")}"
  user_data = "${data.template_file.init_vscode.rendered}"
  
  provisioner "file" {
    connection {
      host = self.ipv4_address
    }
    source      = "conf/vscode"
    destination = "/srv"
  }

  provisioner "file" {
    connection {
      host = self.ipv4_address
    }
    source      = "conf/traefik"
    destination = "/srv"
  }

  provisioner "remote-exec" {
    connection {
      host = self.ipv4_address
    }
    inline = [
      "chmod 600 /srv/traefik/acme.json",
    ]
  }

  provisioner "file" {
    connection {
      host = self.ipv4_address
    }
    content     = "${data.template_file.vscode_compose.rendered}"
    destination = "/srv/vscode/docker-compose.yml"
  }
}

# Create a Server Node with needed Services - Mostly Gitlab, and some additional services like traefik...
# More on this in the REAMDME
resource "hcloud_server" "server" {
  name = "${var.serversubdomain}.${var.instances_domain}"
  image = "ubuntu-18.04"
  # "cx31"=2vCPU 8GB RAM - "cx41"=4vCPU 16GB RAM 
  server_type = "cx51"
  location = "nbg1"
  ssh_keys = "${var.ssh_keys}"
  # user_data = "${file("${path.module}/init.tpl")}"
  user_data = "${data.template_file.init.rendered}"

  # Traefik Files
  provisioner "file" {
    connection {
      host = self.ipv4_address
    }
    source      = "conf/traefik"
    destination = "/srv"
  }

  # Setup Folder Structure
  provisioner "remote-exec" {
    connection {
      host = self.ipv4_address
    }
    inline = [
      "chmod 600 /srv/traefik/acme.json",
      "cd /srv",
      "sudo mkdir -p ./api-demo/volumes/docs",
      "sudo mkdir -p ./api-demo/volumes/static/notifications",
      "sudo mkdir -p ./api-demo/volumes/dbs/notifications",
      "sudo mkdir ./api-demo/volumes/static/users",
      "sudo mkdir ./api-demo/volumes/dbs/users",
      "sudo mkdir ./api-demo/volumes/static/products",
      "sudo mkdir ./api-demo/volumes/dbs/products",
      "sudo mkdir ./api-demo/volumes/static/orders",
      "sudo mkdir ./api-demo/volumes/dbs/orders",
      "sudo mkdir ./api-demo/volumes/static/payments",
      "sudo mkdir ./api-demo/volumes/dbs/payments",
      "sudo mkdir gitlab",
      "cd gitlab",
      "sudo mkdir config",
      "sudo mkdir data",
      "sudo mkdir logs"
    ]
  }

  # NGINX Config
  provisioner "file" {
    connection {
      host = self.ipv4_address
    }
    source      = "conf/api-demo/volumes/nginx"
    destination = "/srv/api-demo/volumes"
  }

  # Gitlab Runner Files
  provisioner "file" {
    connection {
      host = self.ipv4_address
    }
    source      = "conf/gl_runner"
    destination = "/srv/"
  }

  # Swagger API Files
  provisioner "file" {
    connection {
      host = self.ipv4_address
    }
    content     = "${data.template_file.swagger_conf.rendered}"
    destination = "/srv/api-demo/volumes/docs/swagger.yml"
  }

  # Gitlab Config
  provisioner "file" {
    connection {
      host = self.ipv4_address
    }
    content     = "${data.template_file.gitlab_rb.rendered}"
    destination = "/srv/gitlab/config/gitlab.rb"
  }
}

#######################################
# Data                                #
#######################################

# Template for initial configuration of GitLab, bash script
data "template_file" "init" {
#  count = "${var.instances_count}"
  template = "${file("init.tpl")}"
  vars = {
#    password = "${element(local.instances_pw, count.index)}"
    password = "${var.instance_pass}"
  }
}

# Template for the Blank User instances (Linux Docker only)
data "template_file" "init_base" {
  template = "${file("init_linux.tpl")}"
  vars = {
    password = "${var.instance_pass}"
  }
}

# Template for the VS Code User instances (Linux Docker only)
data "template_file" "init_vscode" {
  template = "${file("init_vscode.tpl")}"
  vars = {
    password = "${var.instance_pass}"
  }
}

data "template_file" "vscode_compose" {
  template  = "${file("conf/vscode/docker-compose.yml")}"
  vars      = {
    vscode_pass       = "${var.vscode_pass}"
    dns_suffix        = "${var.serversubdomain}.${var.instances_domain}"
  }
}

data "template_file" "gitlab_rb" {
  template  = "${file("conf/gitlab/config/gitlab.rb")}"
  vars      = {
    gitlab_root_pass      = "${var.gitlab_root_pass}"
    gitlab_runner_token   = "${var.gitlab_runner_token}"
    gitlab_external_url   = "git.${var.serversubdomain}.${var.instances_domain}"
  }
}

data "template_file" "swagger_conf" {
  template  = "${file("conf/api-demo/volumes/docs/swagger.yml")}"
  vars      = {
    swagger_url = "https://${var.serversubdomain}.${var.instances_domain}/api"
  }
}
