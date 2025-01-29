packer {
  required_plugins {
    hyperv = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/hyperv"
    }

    vmware = {
      version = "~> 1"
      source  = "github.com/hashicorp/vmware"
    }
	
    virtualbox = {
      version = ">= v1.1.1"
      source  = "github.com/hashicorp/virtualbox"
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
  validation {
    condition     = length(var.vm_name) > 0
    error_message = "The vm_name must not be empty."
  }  
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

variable "boot_command_bios" {
  type = list(string)
  default = [
	"<tab>", 
	"<end>", 
	" ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.json insecure_installation=1",
    "<wait5s><enter>"
  ]
}

variable "boot_command_efi" {
  type = list(string)
  default = [
	"e", 
	"<down><down><end>", 
	"<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><wait>cdrom",
	" ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.json insecure_installation=1",
    "<wait5s><f10>"
  ]
}

variable "hostname" {
  type    = string
  default = "photon5"
}

variable "boot_partition_size" { # in MB
  type        = number
  default     = 128
}

variable "root_partition_size" { # in MB
  type        = number
  default     = 128
}

variable "swap_partition_size" { # in MB
  type        = number
  default     = 128
}

variable "use_lvm" {
  type        = bool
  default     = false
}

variable "firmware" {
  type    = string
  # Allowed values are bios or efi
  default = ""
  validation {
    condition     = length(var.firmware) == 0 || var.firmware == "bios" || var.firmware == "efi"
    error_message = "The firmware must be 'bios' or 'efi' or blank (in such case the code will default to 'bios' or 'efi' automatically)."
  }  
}

# start of variables specific to virtual box
variable "virtualbox_guest_additions_url" {
  type    = string
}

variable "virtualbox_guest_additions_sha256" {
  type    = string
}

variable "gfx_vram_size" {
  type    = number
  default = 128
}

# end of variables specific to virtual box

source "hyperv-iso" "vm-hyperv" {
  headless         = var.headless

  # boot
  iso_url               = "${var.iso_url}"
  iso_checksum          = "${var.iso_checksum}"
  boot_wait    = "1s" # this must be adjusted according to machine speed. 1s is working for me and 5s is too much.
  boot_command = var.boot_command_efi
  http_content = {
    "/ks.json" = templatefile("${abspath(path.root)}/http/ks.pkrtpl.json", {
	  hostname = var.hostname
	  target_disk    = "sda"
	  bootmode = "efi"  # must be "efi" (generation 2 for Hyper-V)
      ssh_username   = var.ssh_username
      ssh_password   = var.ssh_password
	  use_lvm = convert(var.use_lvm, string)
      boot_partition_size = var.boot_partition_size
      root_partition_size = var.root_partition_size
      swap_partition_size = var.swap_partition_size
	  provider = "hyperv"
    })
  }
  first_boot_device = "DVD" 
  
  # vm profile
  vm_name        = var.vm_name
  generation     = 2 # always as Generation 1 is not working.
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
}

source "vmware-iso" "vm-vmware" {
  # show up when being built
  headless         = var.headless

  # boot related
  iso_url          = "${var.iso_url}"
  iso_checksum     = "${var.iso_checksum}"
  
  boot_wait    = "5s" # adjust this based on your own environment
  boot_command = coalesce(var.firmware, "bios") == "bios" ? var.boot_command_bios : var.boot_command_efi
  http_content = {
    "/ks.json" = templatefile("${abspath(path.root)}/http/ks.pkrtpl.json", {
	  hostname = var.hostname
	  target_disk    = "sda"
	  bootmode = coalesce(var.firmware, "bios")
      ssh_username   = var.ssh_username
      ssh_password   = var.ssh_password
	  use_lvm = convert(var.use_lvm, string)
      boot_partition_size = var.boot_partition_size
      root_partition_size = var.root_partition_size
      swap_partition_size = var.swap_partition_size
	  provider = "vmware"
    })
  }
  
  # vm profile
  vm_name          = "${var.vm_name}"
  version          = "21" # vmware workstation 17 or above
  # vm os type
  guest_os_type    = "vmware-photon-64"

  # Allowed values are bios, efi, and efi-secure (for secure boot)
  firmware = coalesce(var.firmware, "bios")

  # disk
  disk_size        = "${var.vm_disk_size}"
  disk_adapter_type = "sata"
  cdrom_adapter_type = "sata"
  
  # memory & CPU configuration
  memory    = var.vm_memory
  cpus      = var.vm_cpus
  
  ssh_username     = "${var.ssh_username}"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "30m"
  shutdown_command = "shutdown -P now"
  
  # post build
  keep_registered = var.keep_registered
  skip_compaction = false
  skip_export     = var.skip_export
  output_directory = "${var.output_directory}/vmware-workstation/${var.vm_name}"
}

source "virtualbox-iso" "vm-virtualbox" {
  # boot related
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  boot_command     = coalesce(var.firmware, "bios") == "bios" ? var.boot_command_bios : var.boot_command_efi
  boot_wait        = "5s"
  http_content = {
    "/ks.json" = templatefile("${abspath(path.root)}/http/ks.pkrtpl.json", {
	  hostname = var.hostname
	  target_disk    = "sda"
	  bootmode = coalesce(var.firmware, "bios")
      ssh_username   = var.ssh_username
      ssh_password   = var.ssh_password
	  use_lvm = convert(var.use_lvm, string)
      boot_partition_size = var.boot_partition_size
      root_partition_size = var.root_partition_size
      swap_partition_size = var.swap_partition_size
	  provider = "vmware"
    })
  }
  
  vm_name                = var.vm_name
  firmware = coalesce(var.firmware, "bios")
  guest_os_type          = "Linux_64"
  guest_additions_path   = "/root/VBoxGuestAdditions.iso"
  
  guest_additions_url    = var.virtualbox_guest_additions_url
  guest_additions_sha256 = var.virtualbox_guest_additions_sha256
  
  cpus                   = var.vm_cpus
  memory                 = var.vm_memory
  disk_size              = var.vm_disk_size
  hard_drive_interface   = "scsi"     # var.disk_adapter_vbx
  gfx_controller         = "vboxsvga" # var.gfx_controller_vbx
  gfx_vram_size          = var.gfx_vram_size
  headless               = var.headless

  iso_interface = "sata"
  
  # boot_keygroup_interval = "10ms"  # var.boot_key_interval
  
  # ssh
  ssh_username     = "${var.ssh_username}"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "30m"
  ssh_wait_timeout       = "15m" # var.ssh_timeout
  shutdown_command       = "echo '${var.ssh_password}' | sudo -S -E shutdown -P now"

  # post build
  keep_registered = var.keep_registered
  skip_export     = var.skip_export
  output_directory = "${var.output_directory}/virtualbox/${var.vm_name}"
}


build {
	sources = ["source.hyperv-iso.vm-hyperv", "source.vmware-iso.vm-vmware", "source.virtualbox-iso.vm-virtualbox"]
}
