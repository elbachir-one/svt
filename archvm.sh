#!/usr/bin/env bash

# --- arch linux auto installer for qemu made by alpha --- #

# This script automatically installs Arch Linux with some defaults:
# - systemd-boot as the bootloader
# - systemd-networkd for networking
# - Default username, root password, and user password are all set to "arch"

stage1() {
	# ========================
	# part1: Base installation
	# ========================
	setfont -d
	printf '\033c'
	echo "# --- Arch Linux Auto Installer for VM's Made by ALPHA --- #"
	sleep 5s

	device="/dev/vda"
	echo "Selected device: $device"

	echo "Update Keyring"
	sed -i 's/^#Color/Color/' /etc/pacman.conf
	sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 1/' /etc/pacman.conf
	pacman -Sy --noconfirm
	pacman --noconfirm -S archlinux-keyring

	echo "Partition The Disk"
	parted --script "$device" -- mklabel gpt \
		mkpart ESP fat32 1MiB 1024MiB \
		set 1 esp on \
		mkpart primary 1024MiB 100%

	echo "Format root/boot"
	mkfs.vfat -F32 "${device}1"
	mkfs.ext4 "${device}2"

	# Mount partitions
	mount "${device}2" /mnt
	mount --mkdir "${device}1" /mnt/boot

	echo "Install base system"
	pacstrap -K /mnt linux-lts linux-lts-headers base base-devel vim \
	terminus-font efibootmgr git go openssh mtools ntfs-3g dosfstools \
	reflector alsa-utils bash-completion freetype2 libisoburn fuse3 curl wget

	# Generate fstab
	genfstab -U /mnt > /mnt/etc/fstab

	# UUID copy
	getUUID=$(blkid -s UUID -o value "${device}2")
	echo "$getUUID" > /mnt/getuuid

	# Copy second stage of script into new system
	sed '1,/^#stage2$/d' "$0" > /mnt/archvm.sh
	chmod +x /mnt/archvm.sh
	
	# Chroot into system
	arch-chroot /mnt env IN_CHROOT ./archvm.sh
}

stage2() {
	#part2
	# ========================
	# part2: System configure
	# ========================
	printf '\033c'

	echo
	echo "System Configuration"
	# Variables
	rootpassword="arch"
	username="sh"
	userpassword="arch"
	hostname="ARCH"
	keymap="fr"
	font="ter-d20b"
	zone="Africa/Casablanca"

	echo "Hostname"
	echo "$hostname" > /etc/hostname

	echo "Root Password"
	echo "root:$rootpassword" | chpasswd

	echo "Create User"
	useradd -mG wheel "$username"
	echo "$username:$userpassword" | chpasswd
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers

	echo "Timezone & Clock"
	ln -sf "/usr/share/zoneinfo/$zone" /etc/localtime

	hwclock --systohc

	echo "Locale"
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf

	echo "Console Keymap & Font"
	cat > /etc/vconsole.conf <<EOF
KEYMAP=$keymap
FONT=$font
EOF

	echo "Pacman Config"
	sed -i 's/^#Color/Color/' /etc/pacman.conf
	sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 1/' /etc/pacman.conf

	echo "Hosts"
	cat > /etc/hosts <<EOF
127.0.0.1       localhost
::1             localhost
127.0.1.1       $hostname.localdomain $hostname
EOF

	echo "Systemd Networkd"
	tee > /etc/systemd/network/en.network <<EOF
[Match]
Name=en*
[Network]
DHCP=ipv4
EOF

	echo "Enabling services"
	systemctl enable systemd-networkd
	systemctl enable systemd-resolved
	systemctl enable systemd-timesyncd
	sudo systemctl enable reflector
	sudo systemctl enable reflector.timer
	systemctl enable sshd

	echo "Bootloader installation"
	bootctl install

	getUUID=$(cat getuuid)

	tee > /boot/loader/loader.conf <<EOF
default arch
timeout 0
console-mode max
EOF

	tee > /boot/loader/entries/arch.conf <<EOF
title Arch Linux
linux /vmlinuz-linux-lts
initrd /initramfs-linux-lts.img
options root=UUID=$getUUID rw console=ttyS0,115200n8
EOF

	echo "DNS Setup"
	tee > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

	echo "Rebuilding the Initramfs"
	mkinitcpio -P

	echo "Installation complete! Type reboot."
	echo "The User name is ($username) and the password is ($userpassword) also the root password is ($rootpassword)"
}

# ==================
# Script entry point
# ==================
if [ "$IN_CHROOT" = "1" ]; then
	stage2
else
	stage1
fi
