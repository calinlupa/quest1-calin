variable "deployment_targets" {
  description = "A list of deployment targets. Valid values are cloud_run and in the future gke."
  type        = list(string)
  default     = ["cloud_run"]
}

variable "project_id" {
  description = "The GCP project ID."
  type        = string
  default     = "calin-rearc"
}

variable "deployment_regions" {
  description = "A map of Cloud Run regions and their corresponding service names."
  type        = map(string)
  default = {
    us-central1  = "rearc-quest-submission-us"
    europe-west1 = "rearc-quest-submission-eu"
  }
}
