variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region (used as region for standard GKE, we will use a regional cluster)"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC to deploy the cluster into"
  type        = string
}

variable "subnet_name" {
  description = "Name of the Subnet to deploy the cluster into"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "labels" {
  description = "Common labels to apply to resources"
  type        = map(string)
  default     = {}
}
