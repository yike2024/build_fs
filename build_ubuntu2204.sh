#!/bin/bash
FS_DIR=$(pwd)/arm64_jammy_ubuntu2204
ROOTFS=jammy

function build_rootfs()
{
	sudo rm -rf $FS_DIR/$ROOTFS
	mkdir -p $FS_DIR/$ROOTFS

	sudo qemu-debootstrap --arch=arm64 $ROOTFS $FS_DIR/$ROOTFS

	pushd $FS_DIR/$ROOTFS
# following lines must not be started with space or tab.
sudo chroot . /bin/bash << "EOT"

apt update

DEBIAN_FRONTEND=noninteractive apt install -y \
irqbalance kexec-tools busybox-static \
efivar grub-efi-arm64 initramfs-tools overlayroot \
net-tools openssh-server libnss-mdns ethtool \
build-essential flex bison libssl-dev \
pciutils usbutils binutils bsdextrautils \
parted gdisk vim sysstat u-boot-tools \
curl linux-tools-common \
rsync lsof cmake dnsutils python3-dev nginx \
acpid \
libncurses-dev telnet


apt upgrade -y

apt clean

apt install -y python3-flask python3-psutil python3-numpy python3-serial
apt upgrade -y

mount -t proc proc /proc
ln -sf /proc/mounts /etc/mtab
echo "devpts /dev/pts devpts gid=5,mode=620 0 0" >> /etc/fstab
mount -a
apt install sudo
apt upgrade -y

apt clean

sudo adduser --gecos linaro --disabled-login linaro
sudo echo "linaro:linaro" | chpasswd
sudo adduser --gecos admin --disabled-login admin
echo "admin:admin" | chpasswd
usermod -a -G sudo linaro
usermod -a -G sudo admin
usermod -s /bin/bash linaro
usermod -s /bin/bash admin

echo -e "127.0.0.1       sophon\n" >> /etc/hosts
echo -e "sophon\n" > /etc/hostname
echo -e "LC_ALL=C.UTF-8\n" > /etc/default/locale

ln -s /sbin/init /init

exit
EOT
# the end
	sudo rm -f $FS_DIR/rootfs_$ROOTFS.tgz
	sudo tar -czf $FS_DIR/rootfs_$ROOTFS.tgz *
	popd
}

build_rootfs
