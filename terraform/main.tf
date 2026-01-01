terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  # 本番環境ではGCS バックエンドの使用を推奨
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
}

# サブネット
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# ファイアウォール（HTTP 80番ポートを開放）
resource "google_compute_firewall" "http" {
  name    = "${var.environment}-allow-http"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# ファイアウォール（SSH接続用 - 必要に応じて）
resource "google_compute_firewall" "ssh" {
  name    = "${var.environment}-allow-ssh"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh-server"]
}

# VMインスタンス（e2-micro = 毎月1台無料）
resource "google_compute_instance" "app_server" {
  name         = "${var.environment}-app-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable" # Docker専用OS
      type  = "pd-standard"          # Standardディスクを選択（無料枠）
      size  = 30                     # 30GBまで無料
    }
  }

  metadata = {
    # ここでDocker Hubからイメージを引っ張る指定をする
    gce-container-declaration = <<-EOT
      spec:
        containers:
          - name: ${var.container_name}
            image: '${var.docker_image}'
            ports:
              - containerPort: 8080
                hostPort: 80
            env:
              - name: ENVIRONMENT
                value: '${var.environment}'
              - name: PORT
                value: '8080'
        restartPolicy: Always
    EOT
    
    google-logging-enabled = "true"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    
    access_config {
      # 外部IPを自動割り当て
    }
  }

  # ライフサイクル管理
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_id
  }
}

# 最後にアクセスURLを表示させる
output "web_url" {
  description = "Application URL"
  value       = "http://${google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip}"
}

output "instance_name" {
  description = "Instance name"
  value       = google_compute_instance.app_server.name
}

output "external_ip" {
  description = "External IP address"
  value       = google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip
}
