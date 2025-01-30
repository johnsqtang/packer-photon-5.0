# Packer Templates for VMware Photon OS
## Introduction
This repository provides packer templates to build Photon 5.0 OS virtual machines for the following hypervisors/providers:
* Windows Hyper-V
* Vmware Workstation (v17.6+)
* Oracle Virtualbox (v7.16+)
* Proxmox (v8.0.2)
* QEMU for Windows (v9.2.0)
* QEMU/KVM in Linux (v8.2.2)

The above versions have been tested and other versions of hypervisors may or may not work.

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
