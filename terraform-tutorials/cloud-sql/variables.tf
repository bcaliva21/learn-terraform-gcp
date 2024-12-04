variable "project" {
# bunk project id to prevent run up of cloud costs
  default = "terraform-practice-xxxxxx"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-b"
}
