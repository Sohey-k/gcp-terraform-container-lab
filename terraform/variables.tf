variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "docker_image" {
  description = "Docker image path"
  type        = string
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}
