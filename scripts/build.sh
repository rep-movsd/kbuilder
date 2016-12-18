#!/usr/bin/env bash


# Args are <kernel version> <config-file> <mkinitcpio-config-file> [clean]
# 4.7.8 .config-slim mkinitcpio.conf true


KERNEL_VERSION=${1//[^0-9\.]/}
test ${KERNEL_VERSION} == '' && echo Invalid argument for 'version' && exit

CONFIG=${2//[^0-9a-zA-Z_/\.\-]/}
test ${CONFIG} == '' && echo Invalid argument for 'kernel config file' && exit

MKINITCPIOCONF=${3//[^0-9a-zA-Z_/\.\-]/}
test ${MKINITCPIOCONF} == '' && echo Invalid argument for 'mkinitcpio config file' && exit

DELETE=${4//[^a-z]/}

WORKDIR=${5//[^0-9a-zA-Z\/]/}
DATADIR=/data/data
OUTDIR=/data/data/out

sudo mkdir -p ${OUTDIR}
sudo mkdir -p ${WORKDIR}

sudo chown nimbix ${WORKDIR}
sudo chmod 777 ${WORKDIR}

echo Working in ${WORKDIR}
echo Output in ${OUTDIR}



# First extract the version strings
cd ${DATADIR}
IFS='.' read -r -a vers <<< "$KERNEL_VERSION"
CONFIG_LOCALVERSION=$(grep "^CONFIG_LOCALVERSION" ${CONFIG})
IFS='=' read -r -a suff <<< "${CONFIG_LOCALVERSION}"
if [ ${#vers[@]} == 2 ]
then
    vers[2]='0'
fi
LOCAL_VERSION_STR=${suff[1]//[^0-9a-zA-Z_\.\-]/}

MODULE_VERSION=${vers[0]}.${vers[1]}.${vers[2]}${LOCAL_VERSION_STR}

OUT_SUFFIX=${KERNEL_VERSION}${LOCAL_VERSION_STR}

echo Kernel build for Linux version ${KERNEL_VERSION}
echo Kernel module version is ${MODULE_VERSION}
echo Using config file $(basename ${CONFIG})
echo Using local version suffix ${suff[1]}

# Download the file to DATADIR
wget -N https://cdn.kernel.org/pub/linux/kernel/v${vers[0]}.x/linux-${KERNEL_VERSION}.tar.xz

# Copy to WORKDIR (no clobber in case its same dir)
sudo cp -n linux-${KERNEL_VERSION}.tar.xz ${WORKDIR}/

# Enter work dir, delete extracted files if specified
cd ${WORKDIR}
#test ${DELETE} == 'delete' && echo Deleting extracted files if any && rm -rf linux-${KERNEL_VERSION}

echo Extracting archive...
time tar --checkpoint=10000 --checkpoint-action="echo=#%u files extracted" -xf linux-${KERNEL_VERSION}.tar.xz &&

# Do the steps one by one
cd linux-${KERNEL_VERSION} &&
cp ${CONFIG} ./.config &&

echo [Building kernel] &&
time make -j$(nproc) &&

echo [Building modules] &&
make -j$(nproc) modules &&

echo [Installing modules] &&
sudo make modules_install &&

echo [Installing headers] &&
sudo make headers_install &&

echo [Reinstalling nvidia dkms] &&
sudo IGNORE_CC_MISMATCH=1 pacman -S --quiet --needed --noprogressbar --noconfirm nvidia-340xx-dkms

echo [Uninstalling dkms module]
sudo IGNORE_CC_MISMATCH=1 dkms uninstall nvidia/340.101 -k ${MODULE_VERSION}

echo [Reinstalling dkms module] &&
sudo IGNORE_CC_MISMATCH=1 dkms install nvidia/340.101 -k ${MODULE_VERSION} &&

echo [Copying kernel image to output] &&
cp arch/x86/boot/bzImage ${WORKDIR}/vmlinuz-${OUT_SUFFIX} &&

echo [Building initramfs] &&
sudo mkinitcpio mkinitcpio -n -v -c ${MKINITCPIOCONF} -g ${OUTDIR}/initramfs-OUT_SUFFIX.img -k ${MODULE_VERSION} &&

echo [tar.xz-ing all modules] &&
tar --xz -cf ${OUTDIR}/modules-${MODULE_VERSION}.tar.xz /lib/modules/${MODULE_VERSION}/ &&

echo ------------------------ Done ------------------------- &&

echo Built vmlinuz-OUT_SUFFIX and initramfs-OUT_SUFFIX.img

echo Archived /lib/modules/${MODULE_VERSION} into modules-${MODULE_VERSION}.tar.xz

echo && ls -la ${OUTDIR}

#test ${DELETE} == 'delete' && echo Deleting extracted files if any && rm -rf ${WORKDIR}/linux-${KERNEL_VERSION}
