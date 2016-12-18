#!/usr/bin/env bash


# Args are <kernel version> <config-file> <mkinitcpio-config-file> [clean]
# 4.7.8 .config-slim mkinitcpio.conf true

FILEVER=${1//[^0-9\.]/}
test ${FILEVER} == '' && echo Invalid argument for 'version' && exit

CONFIG=${2//[^0-9a-zA-Z_/\.\-]/}
test ${CONFIG} == '' && echo Invalid argument for 'kernel config file' && exit

MKINITCPIOCONF=${3//[^0-9a-zA-Z_/\.\-]/}
test ${MKINITCPIOCONF} == '' && echo Invalid argument for 'mkinitcpio config file' && exit

DELETE=${4//[^a-z]/}


cd /data/data

IFS='.' read -r -a vers <<< "$FILEVER"


CONFIG_LOCALVERSION=$(grep "^CONFIG_LOCALVERSION" ${CONFIG})
IFS='=' read -r -a suff <<< "${CONFIG_LOCALVERSION}"
if [ ${#vers[@]} == 2 ]
then
    vers[2]='0'
fi
SUFFIX=${suff[1]//[^0-9a-zA-Z_\.\-]/}

MODULEDIR=${vers[0]}.${vers[1]}.${vers[2]}${SUFFIX}

echo Kernel build for Linux version ${FILEVER}
echo Kernel module version is ${MODULEDIR}
echo Using config file $(basename ${CONFIG})
echo Using local version suffix ${suff[1]}

wget -N https://cdn.kernel.org/pub/linux/kernel/v${vers[0]}.x/linux-${FILEVER}.tar.xz

test ${DELETE} == 'delete' && echo Deleting extracted files if any && rm -rf linux-${FILEVER}

echo Extracting archive...
time tar --checkpoint=1000 --checkpoint-action="echo=#%u files extracted" -xf linux-${FILEVER}.tar.xz

cd linux-${FILEVER}
cp ${CONFIG} ./.config && \
time make -j$(nproc) && \
make -j$(nproc) modules && \
sudo make modules_install && \
cp arch/x86/boot/bzImage ../vmlinuz-${FILEVER} &&
sudo make headers_install &&
sudo mkinitcpio mkinitcpio -n -v -c ${MKINITCPIOCONF} -g ../initramfs-${FILEVER}${SUFFIX}.img -k ${MODULEDIR} && \
sudo IGNORE_CC_MISMATCH=1 pacman -S --noconfirm nvidia-340xx-dkms &&
sudo IGNORE_CC_MISMATCH=1 dkms install nvidia/340.101 -k ${MODULEDIR}

cd /data/data
tar --xz -cf modules-${MODULEDIR}.tar.xz ${MODULEDIR}/ &&
echo ------------------------ Done ------------------------- &&
echo Built vmlinuz-${FILEVER}${SUFFIX} and initramfs-${FILEVER}${SUFFIX}.img &&
echo Archived /lib/modules/${MODULEDIR} into modules-${MODULEDIR}.tar.xz
test ${DELETE} == 'delete' && echo Deleting extracted files if any && rm -rf linux-${FILEVER}
echo && ls -la /data/data



