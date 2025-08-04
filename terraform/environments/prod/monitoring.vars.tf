
variable "promstack_values_file" {
  type        = string
  description = "Path to the values file for the Prometheus Helm chart"
  default     = "promstack.values.yml"
}
