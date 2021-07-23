# Variables

variable "gcpProject" {
  type = string
}

variable "gcpRegion" {
  type = string
}

variable "gcpZone" {
  type = string
}

variable "labels" {
  type = map(string)
}

variable "tags" {
  type = set(string)
}

variable "subnet_cidr1" {
  type = string
}

variable "subnet_cidr2" {
  type = string
}

variable "fgint1" {
  type = string
}

variable "fgint2" {
  type = string
}

variable "customerAbv" {
  type = string
}

variable "projectName" {
  type = string
}
