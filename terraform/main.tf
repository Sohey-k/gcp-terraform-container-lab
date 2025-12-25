provider "google" {
  project = "your-project-id" # 実際のプロジェクトID
  region  = "us-central1"               # 無料枠対象リージョン
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "free-vpc"
  auto_create_subnetworks = false
}

# サブネット
resource "google_compute_subnetwork" "subnet" {
  name          = "free-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

# ファイアウォール（HTTP 80番ポートを開放）
resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# VMインスタンス（e2-micro = 毎月1台無料）
resource "google_compute_instance" "app_server" {
  name         = "free-app-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable" # Docker専用OS
      type  = "pd-standard"         # ★Standardディスクを選択（無料枠）
      size  = 30                    # 30GBまで無料
    }
  }

  metadata = {
    # ここでDocker Hubからイメージを引っ張る指定をする
    gce-container-declaration = <<EOT
spec:
  containers:
    - name: my-app
      image: 'docker.io/your-docker-id/your-image-name'
      ports:
        - containerPort: 80
          hostPort: 80
  restartPolicy: Always
EOT
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      # 外部IPを自動割り当て
    }
  }
}

# 最後にアクセスURLを表示させる
output "web_url" {
  value = "http://${google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip}"
}
