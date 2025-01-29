packer {
  required_plugins {
    hyperv = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/hyperv"
    }

    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }

    virtualbox = {
      version = ">= v1.1.1"
      source  = "github.com/hashicorp/virtualbox"
    }	
	
    vmware = {
      version = "~> 1"
      source  = "github.com/hashicorp/vmware"
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

#
# variables specific to virtual box --> start
#
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
#
# variables specific to virtual box <-- end
#

#
# variables specific to proxmox --> start
#
variable "proxmox_node" {
  type    = string
  # default = "pve"
}

variable "proxmox_host" {
  type = string
  default = env("PROXMOX_HOST")
}

variable "proxmox_api_token_id" {
  type = string
  default = env("PROXMOX_API_TOKEN_ID")
}

variable "proxmox_api_token" {
  type = string
  default = env("PROXMOX_API_TOKEN")
}

variable "proxmox_disk_storage_pool" {
  type    = string
  # default = "local-lvm"
}

variable "proxmox_cloudinit_storage_pool" {
  type    = string
  # default = "local-lvm"
}

# used by proxmox only
variable "proxmox_disk_format" {
  type    = string
  default = "raw"
}

variable "proxmox_cpu_type" {
  type    = string
  default = "host"
  # The CPU type to emulate. See the Proxmox API documentation for the complete list of accepted values. 
  # For best performance, set this to host. Defaults to kvm64.
}

variable "proxmox_iso_images_loc_prefix" {
  type    = string
}

# not specific to proxmox but used only by the proxmox provider atm
variable "http_bind_address" {
  type    = string
}

variable "vm_cpus_sockets" {
  type    = number
  default = 1
}

#
# variables specific to proxmox <-- end
#

locals {
  firmware = coalesce(var.firmware, "bios")
  
  # convert firmware ("bios" or "efi") to integer
  # 1 - bios
  # 2 - efi
  generation = 1 + index(["bios", "efi"], local.firmware) 
}

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
  generation     = 2 # hard-code to 2 regardless of what is passed for "firmware" as generation 1 is not working
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
  boot_command = local.firmware == "bios" ? var.boot_command_bios : var.boot_command_efi
  http_content = {
    "/ks.json" = templatefile("${abspath(path.root)}/http/ks.pkrtpl.json", {
	  hostname = var.hostname
	  target_disk    = "sda"
	  bootmode = local.firmware
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
  firmware = local.firmware

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
  boot_command     = local.firmware == "bios" ? var.boot_command_bios : var.boot_command_efi
  boot_wait        = "5s"
  http_content = {
    "/ks.json" = templatefile("${abspath(path.root)}/http/ks.pkrtpl.json", {
	  hostname = var.hostname
	  target_disk    = "sda"
	  bootmode = local.firmware
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
  firmware = local.firmware
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

source "proxmox-iso" "vm-proxmox" {
  # proxmox credentials
  proxmox_url = "https://${var.proxmox_host}/api2/json"
  username    = "${var.proxmox_api_token_id}"
  token       = "${var.proxmox_api_token}"
  insecure_skip_tls_verify = true
  node        = var.proxmox_node
  
  vm_name  = "photon-5-template"
  # vm_id = 8189 # could specify the proxmox vm id.
  
  cpu_type = var.proxmox_cpu_type
  os       = "l26" # 2.6+
  memory   = var.vm_memory
  cores    = var.vm_cpus
  sockets  = var.vm_cpus_sockets
  
  # force to "bios" as efi doesn't seem to be working for Photon 5
  bios = "seabios"
  
  boot_wait      = "5s"
  boot_command   = var.boot_command_bios # force to "bios" as efi doesn't seem to be working for Photon 5
  boot_iso {
    type = "sata"
    iso_file = "${var.proxmox_iso_images_loc_prefix}/${basename(var.iso_url)}"
    unmount = true
  }
  
  # important for Windows. this IP must be accessible to the proxmox server
  http_bind_address = var.http_bind_address
  http_port_min = 8000
  http_port_max = 8999
  http_content = {
    "/ks.json" = templatefile("${abspath(path.root)}/http/ks.pkrtpl.json", {
	  hostname = var.hostname
	  target_disk    = "sda"
	  bootmode = "bios" # force to "bios" as efi doesn't seem to be working for Photon 5
      ssh_username   = var.ssh_username
      ssh_password   = var.ssh_password
	  use_lvm = convert(var.use_lvm, string)
      boot_partition_size = var.boot_partition_size
      root_partition_size = var.root_partition_size
      swap_partition_size = var.swap_partition_size
	  provider = "proxmox"
    })
  }

  template_description = "Built from ${basename(var.iso_url)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"

  network_adapters {
    bridge   = "vmbr0"
    firewall = true
    model    = "virtio"
    vlan_tag = var.vlan_id
  }
  
  disks {
    disk_size    = "${var.vm_disk_size}M"
    format       = var.proxmox_disk_format
    io_thread    = true
    storage_pool = var.proxmox_disk_storage_pool
    type         = "scsi"
  }
  scsi_controller = "virtio-scsi-single"
  
  cloud_init              = false
  cloud_init_storage_pool = var.proxmox_cloudinit_storage_pool

  ssh_username     = "${var.ssh_username}"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout           = "60m"
}

build {
	sources = [
		"source.hyperv-iso.vm-hyperv", 
		"source.vmware-iso.vm-vmware", 
		"source.virtualbox-iso.vm-virtualbox", 
		"source.proxmox-iso.vm-proxmox" 
	]
	
	provisioner "shell" {
		only = ["proxmox-iso.vm-proxmox"]
		inline = [ "rm /etc/systemd/system/install-qemu-guest-agent.service",
                   "rm /root/build-qemu-guest-agent.sh"
		         ]
	}  
}
