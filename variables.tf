variable "cloud_id" {
  description = "Yandex Cloud ID. Can be supplied through YC_CLOUD_ID."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID. Can be supplied through YC_FOLDER_ID."
  type        = string
  default     = null  
}

variable "zone" {
  description = "Availability zone for subnet and instances."
  type        = string
  default     = "ru-central1-a"
}

variable "vpc_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "tf-lesson-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet."
  type        = string
  default     = "tf-lesson-subnet"
}

variable "subnet_cidr" {
  description = "IPv4 CIDR block for the subnet."
  type        = string
  default     = "10.10.0.0/24"
}

variable "web_name" {
  description = "Name of the public web virtual machine."
  type        = string
  default     = "web"
}

variable "worker_name" {
  description = "Name of the private worker virtual machine."
  type        = string
  default     = "worker"
}

variable "platform_id" {
  description = "Yandex Cloud compute platform ID."
  type        = string
  default     = "standard-v3"
}

variable "cores" {
  description = "Number of vCPUs for each instance."
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM in GB for each instance."
  type        = number
  default     = 2
}

variable "boot_disk_size" {
  description = "Boot disk size in GB."
  type        = number
  default     = 10
}

variable "ubuntu_image_family" {
  description = "Public image family used to find Ubuntu LTS."
  type        = string
  default     = "ubuntu-2204-lts"
}
