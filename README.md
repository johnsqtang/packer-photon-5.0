# Packer Templates for VMware Photon OS
## Introduction
This repository provides packer templates to build Photon 5.0 OS virtual machines for the following hypervisors/providers:
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
  * [Windows Hyper-V] (optional)
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
### Build Hyper-v VM
  ```console
  packer build -force -only 'hyperv-iso.*' .
  ```
### Build VMware Workstation VM
  ```console
  packer build -force -only 'vmware-iso.*' .
  ```
### Build VMware Workstation VM
  ```console
  packer build -force -only 'vmware-iso.*' .
  ```
### Build Oracle Virtualbox VM
  ```console
  packer build -force -only 'virtualbox-iso.*' .
  ```
### Build QEMU .qcow VM Image
  ```console
  packer build -force -only 'qemu.*' .
  ```
### Build for All Supported Hypervisor Providers
  ```console
  packer build .
  ```
## Default credentials

The default credentials for built VM image are:

|Username|Password|
|--------|--------|
|root|Pssword1!|
