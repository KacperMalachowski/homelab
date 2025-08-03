variable "argocd_admin_password" {
  type        = string
  description = "Admin password for ArgoCD"
  default     = "admin"
  sensitive   = true
}

variable "argocd_values_file" {
  description = "The name of the ArgoCD helm chart values file to use"
  type        = string
  default     = "argocd.values.yml"
}

variable "argocd_image_updater_values_file" {
  description = "The name of the ArgoCD Image Updater helm chart values file to use"
  type        = string
  default     = "argocd-image-updater.values.yml"

}
