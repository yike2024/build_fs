#!/bin/bash
FS_DIR=$(pwd)/arm64_bookworm
ROOTFS=bookworm

function build_rootfs()
{
	sudo rm -rf $FS_DIR/$ROOTFS
	mkdir -p $FS_DIR/$ROOTFS

	sudo qemu-debootstrap --arch=arm64 $ROOTFS $FS_DIR/$ROOTFS

	pushd $FS_DIR/$ROOTFS
# following lines must not be started with space or tab.
sudo chroot . /bin/bash << "EOT"

#mv /etc/apt/sources.list  /etc/apt/sources.list-bak
#echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" | tee /etc/apt/sources.list
apt update

DEBIAN_FRONTEND=noninteractive apt install -y \
irqbalance kexec-tools busybox i2c-tools \
efivar grub-efi-arm64 initramfs-tools overlayroot \
net-tools openssh-server libnss-mdns ethtool ifupdown \
build-essential docker docker.io flex bison libssl-dev \
pciutils usbutils binutils bsdmainutils mmc-utils \
parted gdisk vim sysstat minicom atop u-boot-tools tree \
memtester rng-tools-debian psmisc gawk automake pkg-config bc \
rsync lsof cmake dnsutils python3-dev nginx python3-pip \
acpid curl dnsutils  libgflags-dev \
expect libgoogle-glog-dev libboost-all-dev libev4 \
libev-dev libncurses5-dev libncurses5 libncurses-dev \
libtinfo5 telnet locales

apt upgrade -y

apt clean

apt install -y python3-flask python3-psutil python3-numpy python3-serial
apt upgrade -y

mount -t proc proc /proc
ln -sf /proc/mounts /etc/mtab
echo "devpts /dev/pts devpts gid=5,mode=620 0 0" >> /etc/fstab
mount -a
apt install sudo


adduser --gecos linaro --disabled-login linaro
echo "linaro:linaro" | chpasswd
adduser --gecos admin --disabled-login admin
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
