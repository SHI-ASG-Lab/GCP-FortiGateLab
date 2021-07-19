# Variables
/*
var.project_name
var.region  gcpZone
var.subnet_cidr1
var.subnet_cidr2
var.fgint1
var.fgint2
*/

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
