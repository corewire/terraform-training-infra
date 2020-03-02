# Docker Provider, yay
provider "docker" {
  host = "ssh://root@${var.server_ip}"
}

provider "cloudflare" {
  version = "~> 2.0"
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

# Traefik
resource "docker_container" "Traefik" {
  name        = "Traefik"
  image       = "traefik:1.7"
  #labels      = {
  #  "traefik.enable" = "true"
  #  "traefik.docker.network" = "proxy"
  #  "traefik.frontend.rule" = "Host:proxy.${var.server_dns}"
  #  "traefik.frontend.port" = "8080"
  #}
  restart     = "always"
  mounts {
      source      = "/var/run/docker.sock"
      target      = "/var/run/docker.sock"
      type        = "bind"
  }
  mounts {
      source      = "/srv/traefik/traefik.toml"
      target      = "/traefik.toml"
      type        = "bind"
  }
  mounts {
      source      = "/srv/traefik/acme.json"
      target      = "/acme.json"
      type        = "bind"
  }

  ports {
      internal  = "80"
      external  = "80"
  }
  ports {
      internal  = "443"
      external  = "443"
  }

  networks_advanced{
    name        = docker_network.proxy.name
  }
}

# Gitlab
resource "docker_container" "Gitlab" {
  name            = "Gitlab"
  image           = "gitlab/gitlab-ce:latest"

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.docker.network"
    value = "proxy"
  }
  labels {
    label = "traefik.gitlab.frontend.rule"
    value = "Host:git.${var.server_dns}"
  }
  labels {
    label = "traefik.gitlab.port"
    value = "443"
  }
  restart         = "always"
  networks_advanced{
    name          = docker_network.proxy.name
  }
  ports {
    internal = "22"
    external = "9110"
  }
  mounts {
    source      = "/srv/gitlab/config"
    target      = "/etc/gitlab"
    type        = "bind"
  }
  mounts {
    source      = "/srv/gitlab/logs"
    target      = "/var/log/gitlab"
    type        = "bind"
  }
  mounts {
    source      = "/srv/gitlab/data"
    target      = "/var/opt/gitlab"
    type        = "bind"
  }
}

# Gitlab Runner REGISTER!!! (run once)
resource "docker_container" "gitlab-runner-register" {
  count         = var.gl_runner_register
  depends_on    = [
    docker_container.Gitlab
  ]
  name          = "gitlab-runner"
  image         = "gitlab/gitlab-runner:latest"
  labels {
    label = "traefik.enable"
    value = "false"
  }
  command       = [
    "register",
    "--non-interactive",
    "--executor",
    "docker",
    "--docker-image",
    "ubuntu:latest",
    "--url",
    "https://git.${var.server_dns}/",
    "--registration-token",
    "${var.gl_runner_token}",
    "--run-untagged=true",
    "--docker-volumes",
    "/var/run/docker.sock:/var/run/docker.sock",
    "--locked=false"
  ]
  mounts {
    source      = "/srv/gl_runner/config"
    target      = "/etc/gitlab-runner"
    type        = "bind"
  }
  mounts {
    source      = "/var/run/docker.sock"
    target      = "/var/run/docker.sock"
    type        = "bind"
  }
}

resource "docker_container" "gitlab-runner" {
  count         = var.gl_runner_count
  depends_on    = [
    docker_container.gitlab-runner-register
  ]
  name          = "gitlab-runner"
  image         = "gitlab/gitlab-runner:latest"
  labels {
    label = "traefik.enable"
    value = "false"
  }
  mounts {
    source      = "/srv/gl_runner/config"
    target      = "/etc/gitlab-runner"
    type        = "bind"
  }
  mounts {
    source      = "/var/run/docker.sock"
    target      = "/var/run/docker.sock"
    type        = "bind"
  }
}
#########################################
#########################################
########        Demo-Api        #########
#########################################
#########################################

resource "docker_container" "app-nginx" {
  depends_on      = [
    docker_container.swagger,
    docker_container.app-notifications,
    docker_container.app-users,
    docker_container.app-products,
    docker_container.app-orders,
    docker_container.app-soap,
    docker_container.app-payments
  ]
  name            = "app-nginx"
  image           = "nginx"
  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.docker.network"
    value = "proxy"
  }
  labels {
    label = "traefik.gitlab.frontend.rule"
    value = "Host:${var.server_dns}"
  }
  labels {
    label = "traefik.gitlab.port"
    value = "80"
  }
  restart         = "always"
  
  networks_advanced {
    name          = docker_network.proxy.name
  }
  networks_advanced {
    name          = docker_network.api.name
  }
  mounts {
    source      = "/srv/api-demo/volumes/nginx/nginx.conf"
    target      = "/etc/nginx/conf.d/default.conf"
    read_only   = "true"
    type        = "bind"
  }
  mounts {
    source      = "/srv/api-demo/volumes/static"
    target      = "/usr/share/nginx/static"
    type        = "bind"
  }
}
resource "docker_container" "swagger" {
  name            = "swagger"
  image           = "swaggerapi/swagger-ui"
  restart         = "always"
  
  networks_advanced {
    name          = docker_network.api.name
  }
  env = [
    "SWAGGER_JSON=/docs/swagger.yml",
    "BASE_URL=/api"
  ]
  mounts {
    source      = "/srv/api-demo/volumes/docs"
    target      = "/docs"
    type        = "bind"
  }
}
resource "docker_container" "app-notifications" {
  name            = "app-notifications"
  image           = "registry.derdurner.de/external/demo-api-notifications"
  restart         = "always"
  
  networks_advanced {
    name          = docker_network.api.name
  }
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  mounts {
    source      = "/srv/api-demo/volumes/static/notifications"
    target      = "/static"
    type        = "bind"
  }
  mounts {
    source      = "/srv/api-demo/volumes/dbs/notifications"
    target      = "/usr/src/app/db"
    type        = "bind"
  }
}

resource "docker_container" "app-users" {
  name            = "app-users"
  image           = "registry.derdurner.de/external/demo-api-users"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.api.name
  }
  mounts {
    source      = "/srv/api-demo/volumes/static/users"
    target      = "/static"
    type        = "bind"
  }
  mounts {
    source      = "/srv/api-demo/volumes/dbs/users"
    target      = "/usr/src/app/db"
    type        = "bind"
  }
}

resource "docker_container" "app-products" {
  name            = "app-products"
  image           = "registry.derdurner.de/external/demo-api-products"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.api.name
  }
  mounts {
    source      = "/srv/api-demo/volumes/static/products"
    target      = "/static"
    type        = "bind"
  }
  mounts {
    source      = "/srv/api-demo/volumes/dbs/products"
    target      = "/usr/src/app/db"
    type        = "bind"
  }
}

resource "docker_container" "app-orders" {
  name            = "app-orders"
  image           = "registry.derdurner.de/external/demo-api-orders"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.api.name
  }
  mounts {
    source      = "/srv/api-demo/volumes/static/orders"
    target      = "/static"
    type        = "bind"
  }
  mounts {
    source      = "/srv/api-demo/volumes/dbs/orders"
    target      = "/usr/src/app/db"
    type        = "bind"
  }
}
resource "docker_container" "app-payments" {
  name            = "app-payments"
  image           = "registry.derdurner.de/external/demo-api-payments"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.api.name
  }
  mounts {
    source      = "/srv/api-demo/volumes/static/payments"
    target      = "/static"
    type        = "bind"
  }
  mounts {
    source      = "/srv/api-demo/volumes/dbs/payments"
    target      = "/usr/src/app/db"
    type        = "bind"
  }
}
resource "docker_container" "app-soap" {
  name            = "app-soap"
  image           = "registry.derdurner.de/external/demo-api-soap"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.api.name
  }
}

#########################################
#########################################
########    Staging-Demo-Api    #########
#########################################
#########################################

resource "docker_container" "staging-app-nginx" {
  depends_on      = [
#    docker_container.staging-swagger,
    docker_container.staging-app-notifications,
    docker_container.staging-app-users,
    docker_container.staging-app-products,
    docker_container.staging-app-orders,
    docker_container.staging-app-soap,
    docker_container.staging-app-payments
  ]
  name            = "staging-app-nginx"
  image           = "nginx"
  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.docker.network"
    value = "proxy"
  }
  labels {
    label = "traefik.gitlab.frontend.rule"
    value = "Host:staging.${var.server_dns}"
  }
  labels {
    label = "traefik.gitlab.port"
    value = "80"
  }
  restart         = "always"
  
  networks_advanced {
    name          = docker_network.proxy.name
  }
  networks_advanced {
    name          = docker_network.staging-api.name
    aliases       = ["app-nginx"]
  }
  mounts {
    source      = "/srv/api-demo/volumes/nginx/staging-nginx.conf"
    target      = "/etc/nginx/conf.d/default.conf"
    read_only   = "true"
    type        = "bind"
  }
  mounts {
    source      = "/srv/api-demo/volumes/static"
    target      = "/usr/share/nginx/static"
    type        = "bind"
  }
}
resource "docker_container" "staging-app-notifications" {
  name            = "staging-app-notifications"
  image           = "registry.derdurner.de/external/demo-api-notifications"
  restart         = "always"
  
  networks_advanced {
    name          = docker_network.staging-api.name
    aliases       = ["app-notifications"]
  }
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
}

resource "docker_container" "staging-app-users" {
  name            = "staging-app-users"
  image           = "registry.derdurner.de/external/demo-api-users"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.staging-api.name
    aliases       = ["app-users"]
  }
}

resource "docker_container" "staging-app-products" {
  name            = "staging-app-products"
  image           = "registry.derdurner.de/external/demo-api-products"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.staging-api.name
    aliases       = ["app-products"]
  }
}

resource "docker_container" "staging-app-orders" {
  name            = "staging-app-orders"
  image           = "registry.derdurner.de/external/demo-api-orders"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.staging-api.name
    aliases       = ["app-orders"]
  }
}
resource "docker_container" "staging-app-payments" {
  name            = "staging-app-payments"
  image           = "registry.derdurner.de/external/demo-api-payments"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.staging-api.name
    aliases       = ["app-payments"]
  }
}
resource "docker_container" "staging-app-soap" {
  name            = "staging-app-soap"
  image           = "registry.derdurner.de/external/demo-api-soap"
  restart         = "always"
  env           = [
    "DJANGO_BASE_PATH=api/"
  ]
  
  networks_advanced {
    name          = docker_network.staging-api.name
    aliases       = ["app-soap"]
  }
}

#########################################
#########################################
########        Networks        #########
#########################################
#########################################
resource "docker_network" "api" {
  name      = "api"
  internal  = "false"
}

resource "docker_network" "staging-api" {
  name      = "staging-api"
  internal  = "false"
}

resource "docker_network" "proxy" {
  name = "proxy"
  internal = "false"
}


#
## Nginx TEST
#resource "docker_container" "nginx_test" {
#  name = "tf-test-nginx"
#  labels = {
#    "traefik.enable" = "true"
#    "traefik.docker.network" = "proxy"
#    "traefik.basic.frontend.rule" = "Host:test.derdurner.de"
#    "traefik.basic.frontend.port" = "80"
#  }
#  #ports {
#  #  internal = "80"
#  #  external = "80"
#  #}
#  env = [
#    "NGINX_HOST=test.derdurner.de",
#    "NGINX_PORT=80"
#  ]
#  image = "nginx"
#  networks_advanced {
#    name = "${docker_network.proxy.name}"
#  }
#}
#
# traefik network
