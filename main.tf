provider "yandex" {
  service_account_key_file = pathexpand("~/.config/yandex-cloud/key.json")
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = var.ubuntu_image_family
}

resource "yandex_vpc_network" "this" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "this" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.subnet_cidr]
}

resource "yandex_vpc_security_group" "web" {
  name       = "tf-lesson-web-sg"
  network_id = yandex_vpc_network.this.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from anywhere (restrict this in production)"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP application on port 8080"
    port           = 8080
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Allow outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "worker" {
  name       = "tf-lesson-worker-sg"
  network_id = yandex_vpc_network.this.id

  ingress {
    protocol          = "TCP"
    description       = "SSH only from the lesson subnet"
    port              = 22
    v4_cidr_blocks    = [var.subnet_cidr]
  }

  egress {
    protocol       = "ANY"
    description    = "Allow outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_compute_instance" "web" {
  name        = var.web_name
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores  = var.cores
    memory = var.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.boot_disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    user-data = <<-CLOUD_CONFIG
      #cloud-config
      package_update: true
      packages:
        - docker.io
      runcmd:
        - [systemctl, enable, --now, docker]
        - [docker, pull, nginx:latest]
        - [docker, run, -d, --restart=unless-stopped, --name, web-nginx, -p, 8080:80, nginx:latest]
    CLOUD_CONFIG
  }
}

resource "yandex_compute_instance" "worker" {
  name        = var.worker_name
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores  = var.cores
    memory = var.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.boot_disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.worker.id]
  }

  metadata = {
    user-data = <<-CLOUD_CONFIG
      #cloud-config
      package_update: true
      packages:
        - python3
      write_files:
        - path: /usr/local/bin/worker-loop.sh
          permissions: "0755"
          owner: root:root
          content: |
            #!/bin/bash
            while true; do
              echo "Task $(date)" >> /var/log/worker.log
              sleep 60
            done
      runcmd:
        - [bash, -lc, "nohup /usr/local/bin/worker-loop.sh >/dev/null 2>&1 &"]
    CLOUD_CONFIG
  }
}
