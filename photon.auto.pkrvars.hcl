iso_url      = "https://packages.vmware.com/photon/5.0/GA/iso/photon-minimal-5.0-dde71ec57.x86_64.iso"
# In order for QEMU on Windows to work, iso_url must point to a ***local*** file path like below.
# iso_url      = "photon-minimal-5.0-dde71ec57.x86_64.iso"
iso_checksum = "691d09eb61f8cad470f21c88287ff6b005c3be365c926a87577e714aee2d46bc" # sha256 checksum

# the following two settings are used to build QEMU VM image(.qcow2) on Windows. 
# They work fine in my environment but may need modifications.
qemu_windows_machine = "type=pc,accel=whpx,kernel-irqchip=off" # run "qemu-system-x86_64 -machine help" in DOS/Powershell to get a list of machines avaiable
qemu_windows_cpu     = "Nehalem"                               # run "qemu-system-x86_64 -cpu help"     in DOS/Powershell to get a list of available cpus
