variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "docker_image" {
  description = "Docker image path (e.g., docker.io/username/image:tag)"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for compute instance"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-micro"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "ssh_source_ranges" {
  description = "Source IP ranges for SSH access"
  type        = list(string)
  default     = [] # 空にするとSSHファイアウォールルールは作成されるが、どこからもアクセス不可
}
