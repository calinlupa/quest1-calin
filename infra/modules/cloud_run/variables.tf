variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
}

variable "location" {
  description = "The GCP region where the Cloud Run service will be deployed."
  type        = string
}

variable "image" {
  description = "The container image to deploy."
  type        = string
}

variable "container_port" {
  description = "The port the container listens on."
  type        = number
  default     = 3000
}

variable "secret_word" {
  description = "The secret word to be used as an environment variable."
  type        = string
  sensitive   = true
}

variable "min_instance_count" {
  description = "The minimum number of container instances that the service must run. Set to 0 to allow scaling to zero."
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "The maximum number of container instances that the service can scale up to."
  type        = number
  default     = 10 # A sensible default for scaling
}

variable "cpu_limit" {
  description = "The CPU limit for the container instance."
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "The memory limit for the container instance."
  type        = string
  default     = "512Mi"
}
