# Packer Templates for Photon OS
## Introduction
This repository provides packer templates to build [Photon OS](https://vmware.github.io/photon/) 5.0 virtual machines for the following hypervisors/providers:
* Windows Hyper-V
* Vmware Workstation (v17.6+)
* Oracle Virtualbox (v7.16+)
* Proxmox (v8.0.2)
* QEMU .qcow2 images
  * Build on Windows using QEMU for Windows (v9.2.0) 
  * Build on Linux with QEMU/KVM installed

The above versions have been tested and other versions of hypervisors may or may not work.

## Prerequisites

* [Packer](https://www.packer.io/downloads.html)
  * <https://www.packer.io/intro/getting-started/install.html>
* Hypervisors
  * Windows Hyper-V: Windows feature enabled (optional)
  * [VMware Workstation](https://www.vmware.com/products/workstation-pro.html) (optional)
  * [Oracle VirtualBox](https://www.virtualbox.org/) (optional)
  * [QEMU for Windows (MSYS2 UCRT64)](https://www.qemu.org/download/#windows) (optional)
* Install ISO maker (used by packer)
  * On Windows 10+: it is suggested to install **oscdimg.exe**
    * Visit https://go.microsoft.com/fwlink/?linkid=2271337 to download *adksetup.exe*
    * Run *Windows Assessment and Deployment Kit* (adksetup.exe)
    * Take the default installation path *C:\Program Files (x86)\Windows Kits\10\*
    * Uncheck all other except the *Deployment Tools* option
    * Add *C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg* (working for both 32 and 64 bits) or *C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg* (working for 64 bit only) to your System or User PATH.
    * Go to DOS and type **oscdimg.exe** followed by RETURN to test whether oscdimg.exe can be run successfully.
  * On Linux: install mkisofs
 https://github.com/marcinbojko/hv-packer/
* Open firewall ports 8000-9000 (default ports used by packer when building a http server on the fly) (credits to [marcinbojko/hv-packer](https://github.com/marcinbojko/hv-packer/)).
  * On Windows: go to powershell in admin mode and then run:
    ```powershell
    Remove-NetFirewallRule -DisplayName "Packer_http_server" -Verbose
    New-NetFirewallRule -DisplayName "Packer_http_server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000-9000
     
## Get Started

### Step 1 - Clone the Repository

Clone the project repository.
  ```console
  git clone https://github.com/johnsqtang/packer-photon-5.0.git
  ```
### Step 2 - Update Input Variables
The following *.auto.pkrvars.hcl file must be updated before doing packer build:
* photon.auto.pkrvars.hcl: contains most basic variables for all provider
* proxmox.auto.pkrvars.hcl.EXAMPLE: contains a tempalte for minimum variables for building Proxmox VMs.
* virtualbox.auto.pkrvars.hcl: contains variables for Oracle Virtualbox VMs.

#### photon.auto.pkrvars.hcl
By default, iso_url points to a remote https url. In order to build QEMU images under Windows successfully, one must download the Photon OS image first, and then update iso_url and iso_checksum, accordingly.

#### proxmox.auto.pkrvars.hcl.EXAMPLE
This file must be renamed to proxmox.auto.pkrvars.hcl and then each variable must be checked and/or updated before starting to build a Proxmox VM template.

#### virtualbox.auto.pkrvars.hcl
The settubgs in this file works for Oracle Virtualbox v7.16. If one got a different version, this file needs to be updated accordingly.

### Step 3 - Initialize Packer plugins
Go to the packer-photon-5.0 folder and then issue the following command:
  ```console
  packer init photon.auto.pkrvars.hcl
  ```

## Build
The output for Hyper-V, VMware Workstation, Oracle Virtualbox and QEMU goes to the *output/* sub folder. The output of the template for Proxmox, of cause, goes to Proxmox server.

### Basic Usage
#### Build Hyper-v VM
  ```console
  packer build -only 'hyperv-iso.*' .
  ```
#### Build VMware Workstation VM
  ```console
  packer build -only 'vmware-iso.*' .
  ```
#### Build Oracle Virtualbox VM
  ```console
  packer build -only 'virtualbox-iso.*' .
  ```
#### Build Proxmox VM Template
  ```console
  packer build -only 'proxmox-iso.*' .
  ```
During the build process, qemu-guest-agent is being compiled using [snapshotleisure SPEC](https://github.com/snapshotleisure/photon-os-qemu-guest-agent), which utilizes [Photon OS's build_spec.sh](https://github.com/vmware/photon/blob/master/tools/scripts/build_spec.sh). 
Once qemu-guest-agent is built successfully, it will be installed on the VM. 

The compling process takes place inside a docker and there is no screen output during the stage. It takes time and just be patient!

#### Build QEMU .qcow2 VM Image
  ```console
  packer build -only 'qemu.*' .
  ```
Then we could launch the built VM image like below using qemu-system-x86_64:

On Linux:
  ```console
  qemu-system-x86_64 -m size=2048m \
    -enable-kvm -cpu host \
    -device virtio-scsi-pci,id=scsi0 \
    -drive if=none,file=output/qemu/photon-minimal-5.0-dde71ec57.x86_64.iso.qcow2,format=qcow2,id=disk0 \
    -device scsi-hd,drive=disk0
  ```
On Windows (including WSYS2) console:
  ```console
  qemu-system-x86_64 -m size=2048m  \
    -machine type=pc,accel=whpx,kernel-irqchip=off \
    -device virtio-scsi-pci,id=scsi0 \
    -drive if=none,file=output/qemu/photon-minimal-5.0-dde71ec57.x86_64.iso.qcow2,format=qcow2,id=disk0 \
    -device scsi-hd,drive=disk0
  ```

#### Build for All Supported Hypervisor Providers
  ```console
  packer build .
  ```
This would takes quite a while depending on the speed of the build machine.

### Advanced Usage
We could pass variable values from command line to fine-tune VM to be built. For example, if we would like to build a Hyper-V vm with disk size of 20G, we could do this:
  ```console
  packer build -only 'hyperv-iso.*' -var vm_disk_size 20000 .
  ```

If we would also like the virtual machine name to be 'Photon 5.0 built by Packer', we could do this:
  ```console
  packer build -only 'hyperv-iso.*' -var vm_disk_size 20000 -var 'vm_name=Photon 5.0 built by Packer' 20000 .

  # or
  packer build -only 'hyperv-iso.*' -var vm_disk_size 20000 -var vm_name='Photon 5.0 built by Packer' 20000 .
  ```
Note that we have to put quotes as the value contains spaces.

Those input variables defined in *photon.pkr.hcl* but not in .auto.pkrvars.hcl files can be passed in form of *-var variable_name=value*.

## bios or uefi

|Hypervisor| bios/MBR | efi/uefi/gpt (Hyper-v's Generation 2) |
|----------|----------|---------------------------------------|
|Hyper-V|Not working|Yes|
|VMware workstation|Yes|Yes|
|Oracle VirtualBox|Yes|Yes|
|Proxmox|Yes|No|
|QEMU|Yes|No|


## What are challenges for Building Photon OS 5.0 Using Packer?
To build Photon QEMU .qcow images on Windows, I have to *hack* the packer for two reasons:
1. Photon OS 5.0 installer seems to be working **only** for sda drives (CDROM + disk). If, for example, we instruct packer & qemu plugin to generate an *ide* CDROM and a *sata* disk, although the .iso will boot up, subsequent steps will fail with this error message: *Exception: Installer failed with error: Canot proceed with the installation because the installation medium is not readable. Ensure that you select a medium connected to a SATA interface*. I used *fdisk --list* and the installer detects only the disk, not the ide CDROM.
1. any combination of *disk_interface* and *cdrom_interface* of the packer QEMU plugin would not give me two *sda* drives.
  * If I set cdrom_interface = "sata" and disk_interface = "virtio-scsi", I would get this error from packer: *...id=cdrom0,media=cdrom: unsupported bus type 'sata'*
  * If I set cdrom_interface = "virtio-scsi" and disk_interface = "virtio-scsi", I would get this error from packer: *No 'virtio-bus' bus found for device 'virtio-scsi-device'*

I finally found a workaround: inject *-device* and *-drive* settings into the *qemuargs* property to override those qemu parameters generated by packer! This works very well except when the iso_url points to an http/https url.

I am not sure whether it would be a bug or a feature that packer could not generate two *sda* drives without applying *qemuargs*. 

What is very interesting is that on Linux (including WSL2) the Photon OS 5.0 installer doesn't seem to require that CDROM be *ide* interface. As such, I don't need to hack the *qemuargs* property. The following two scenarios are working fine for me when packer is run on Linux:
* CDROM uses *ide* and disk uses *virtio-scsi*
* CDROM uses *ide* and disk uses *virtio*

## Default credentials

The default credentials for built VM image are:

|Username|Password|
|--------|--------|
|root|Pssword1!|
