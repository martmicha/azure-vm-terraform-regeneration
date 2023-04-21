variable "location" {}
variable "admin_username" {}
variable "admin_password" {}
variable "docker_image" {
  type    = string
  default = "martmich/todoappwithlogin"
}

variable "docker_tag" {
  type    = string
  default = "latest"
}