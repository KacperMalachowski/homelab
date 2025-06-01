terraform {
  backend "gcs" {
    bucket = "malachowski-state"
    prefix = "prod"
  }
}