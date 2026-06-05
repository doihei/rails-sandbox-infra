variable "project_id" { type = string }

variable "region" {
  type    = string
  default = "asia-northeast1"
}

variable "rails_image" { type = string }
variable "front_image" { type = string }