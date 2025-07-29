variable "manager_count" {
  description = "Number of manager servers to create"
  type        = number
  default     = 1

  validation {
    condition     = var.manager_count > 0
    error_message = "The number of manager servers must be greater than zero"
  }
}

variable "ssh_public_key" {
  description = "Map of SSH public keys to use for the servers"
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.ssh_public_key) > 0
    error_message = "At least one SSH public key must be provided"
  }
}