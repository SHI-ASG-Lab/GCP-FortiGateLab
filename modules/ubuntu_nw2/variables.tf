# Variable Declarations

variable "gcpProject" {
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

variable "ub2Name" {
  type = string
}

variable "disk2Name" {
  type = string
}

variable "network2" {
  type = string
}

variable "subnetwork2" {
  type = string
}

