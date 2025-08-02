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