#!/usr/bin/env bash

# --- Artix Linux auto installer for qemu made by alpha --- #

# This script automatically installs Artix Linux with some defaults
# - Default username, root password, and user password are all set to "artix"

stage1() {
	# ========================
	# part1: Base installation
	# ========================
	setfont -d
	printf '\033c'
	echo "# --- Artix Linux Auto Installer for VM's Made by ALPHA --- #"
	sleep 5s

	device="/dev/vda"
	echo "Selected device: $device"

	echo "Update Keyring"
	sed -i 's/^#Color/Color/' /etc/pacman.conf
	sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 1/' /etc/pacman.conf
	pacman -Sy --noconfirm
	pacman --noconfirm -S artixlinux-keyring

	echo "Partition The Disk"
	parted --script "$device" -- mklabel gpt \
		mkpart ESP fat32 1MiB 129MiB \
		set 1 esp on \
		mkpart primary 129MiB 100%

	echo "Format root/boot"
	mkfs.vfat -F32 "${device}1"
	mkfs.ext4 "${device}2"

	mount "${device}2" /mnt
	mount --mkdir "${device}1" /mnt/boot

	echo "Install base system"
	basestrap -K /mnt linux-lts linux-lts-headers base base-devel vim wget \
	terminus-font efibootmgr git go mtools ntfs-3g dosfstools curl reflector \
	alsa-utils bash-completion freetype2 libisoburn fuse3 dinit openssh-dinit \
	networkmanager-dinit

	fstabgen -U /mnt > /mnt/etc/fstab

	getUUID=$(blkid -s UUID -o value "${device}2")
	echo "$getUUID" > /mnt/getuuid

	# Copy second stage of script into new system
	sed '1,/^#stage2$/d' "$0" > /mnt/artixvm.sh
	chmod +x /mnt/artixvm.sh

	artix-chroot /mnt env IN_CHROOT ./artixvm.sh
}

stage2() {
	#part2
	# ========================
	# part2: System configure
	# ========================
	printf '\033c'

	echo
	echo "System Configuration"
	rootpassword="artix"
	username="sh"
	userpassword="artix"
	hostname="ARTIX"
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
