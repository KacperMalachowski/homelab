variable "ssh_public_key" {
  description = "The public key to use for SSH access to the Docker host"
  type        = map(string)

  validation {
    condition     = length(keys(var.ssh_public_key)) > 0
    error_message = "At least one SSH public key must be defined"
  }
}

variable "server_number" {
  description = "Number of servers to create"
  type        = number
  default     = 1

  validation {
    condition     = var.server_number > 0
    error_message = "The number of servers must be greater than zero"
  }
}

variable "prefix" {
  description = "The prefix to use for all resource names"
  type        = string
  default     = "srv"
}

variable "type" {
  description = "The type of server to create"
  type        = string
  default     = "cx22"

  validation {
    condition     = var.type != ""
    error_message = "Server type must be specified"
  }
  
}

variable "image" {
  description = "The image to use for the server"
  type        = string
  default     = "debian-12"

  validation {
    condition     = var.image != ""
    error_message = "Image must be specified"
  }
}

variable "location" {
  description = "The location to create the server in"
  type        = string
  default     = "fsn1"

  validation {
    condition     = var.location != ""
    error_message = "Location must be specified"
  }
}

variable "backups" {
  description = "Whether to enable backups for the server"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the server"
  type        = map(string)
  default     = {}
}