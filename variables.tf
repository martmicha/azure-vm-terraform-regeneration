variable "location" {}
variable "admin_username" {}
variable "admin_password" {}
variable "docker_image" {
  type = string
}

variable "docker_tag" {
  type = string
}
variable "location" {
  type = string
  default = "northeurope"
}