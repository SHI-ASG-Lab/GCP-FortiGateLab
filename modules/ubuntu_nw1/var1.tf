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

variable "victimName" {
  type = string
}

variable "diskName" {
  type = string
}

variable "network1" {
  type = string
}

variable "subnetwork1" {
  type = string
}
