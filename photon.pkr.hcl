packer {
  required_plugins {
    hyperv = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

variable "iso_url" {
  type = string
}

variable "iso_checksum" {
  type = string
}

variable "headless" {
  type        = bool
  description = "Headless"
  default     = true
}

variable "vm_name" {
  type    = string
  default = "Photon 5.0"
}

variable "vm_cpus" {
  type    = number
  default = 2
}

variable "vm_memory" {
  type    = number
  default = 4096
}

variable "vm_disk_size" {
  type    = number
  default = 20000
}

variable "output_directory" {
  type    = string
  default = "output"
}

variable "temp_path" {
  type    = string
  default = "temp"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_password" {
  type    = string
  default = "Pssword1!"
}

variable "switch_name" {
  type    = string
  default = "Default Switch"
}

variable "vlan_id" {
  type    = string
  default = ""
}

variable "skip_export" {
  type        = bool
  description = "Skip export"
  default     = false
}

variable "keep_registered" {
  type    = bool
  default = false
}

variable "boot_command" {
  type = list(string)
  default = [
	"e", 
	"<down><down><end>", 
	"<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><wait>cdrom",
	" ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.json insecure_installation=1",
    "<wait5s><f10>"
  ]
}

source "hyperv-iso" "vm-hyperv" {
  headless         = var.headless

  # boot
  iso_url               = "${var.iso_url}"
  iso_checksum          = "${var.iso_checksum}"
  boot_wait    = "1s" # this must be adjusted according to machine speed. 1s is working for me and 5s is too much.
  boot_command = var.boot_command
  http_directory = "http"
  first_boot_device = "DVD" 
  
  # vm profile
  vm_name        = var.vm_name
  generation     = 2
  enable_secure_boot    = false
  enable_dynamic_memory = false
  guest_additions_mode  = "disable"
 
  cpus           = var.vm_cpus
  memory         = var.vm_memory
  disk_size      = var.vm_disk_size

  # network
  switch_name  = var.switch_name
  vlan_id      = var.vlan_id

  # ssh
  communicator          = "ssh"
  ssh_username          = "${var.ssh_username}"
  ssh_password          = "${var.ssh_password}"
  ssh_timeout           = "60m"

  shutdown_command = "shutdown -P now"
  shutdown_timeout      = "5m"

  # build instructions
  keep_registered = var.keep_registered
  skip_export = var.skip_export
  output_directory = "${var.output_directory}/hyperv/${var.vm_name}"
  # temp_path        = "${var.temp_path}"
}

build {
   sources = ["source.hyperv-iso.vm-hyperv"]
}
