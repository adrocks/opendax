variable "credentials" {
  type = string
}

variable "ssh_user" {
  type        = string
  description = "Name of the SSH user to use"
  default     = "app"
}

variable "ssh_public_key" {
  type        = string
}

variable "ssh_private_key" {
  type        = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "image" {
  type = string
}

variable "cloudflare_token" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

