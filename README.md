Arch Linux Kernel Builder 
-------------------------

Builds a Linux Kernel using the Arch Linux method and tools

Command Parameters:
 
 - Kernel major version number (e.g. 4)
 - Kernel full version (e.g. 4.9 or 4.8.15)
 - Kernel extended version string (e.g. 4.9.0 or 4.8.15)
 - Custom kernel release name suffix (e.g. mothra)



Inputs (in drop.nimbix.net):
 
 - Kernel config file: .config-version-release
 - Initial RAM FS config: mkinitcpio.conf
 

Outputs (in drop.nimbix.net):

 - Kernel image: vmlinuz-version-release
 - Initial ram disk: initramfs-version-release.img



1) Specified version of kernel source is downloaded into drop.nimbix.net (if non existent) 
2) Kernel is extracted (to vault) and specified kernel config file is applied
3) TODO : allow interactive make oldconfig
4) kernel is built
5) modules are installed
6) dkms is run (nvidia-340xx-dkms exists by default)
7) TODO : Allow adding other dkms packages
8) mkinitcpio is run using the provided config file
9) Outputs copied to drop.nimbix.net


TODO:
Allow clean and rebuild without download
Automatically delete the extracted folder or image 
