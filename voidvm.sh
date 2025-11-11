#!/usr/bin/env bash

#
# --- Void Linux Auto Installer For Qemu Made by El Bachir - <elbachir.org> --- #
#

stage1() {
	# ========================
	# part1: Base installation
	# ========================
	printf '\033c'
	echo "#-- Void Linux Auto Installer For Qemu Made by El Bachir - <elbachir.org> --#"
	sleep 3s

	device="/dev/vda"
	echo "Selected device: $device"

	xbps-install -S
	xbps-install -uy xbps
	echo "Installing Parted"
	xbps-install -Sy parted

	mounted=$(lsblk -ln -o MOUNTPOINT "$device" | grep -v '^$')

	if [ -n "$mounted" ]; then
		echo "Unmounting mounted partitions on $device..."
		for mp in $mounted; do
			umount -l "$mp" 2>/dev/null || true
		done
	fi

	wipefs -a "$device"

	parted --script "$device" -- mklabel gpt \
		mkpart ESP fat32 1MiB 512MiB \
		set 1 esp on \
		mkpart primary 512MiB 100%

	partprobe "$device"
	sleep 1

	mkfs.vfat -F32 "${device}1"
	mkfs.ext4 "${device}2"

	mount "${device}2" /mnt
	mount --mkdir "${device}1" /mnt/boot

	mkdir -p /mnt/var/db/xbps/keys
	cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

	xbps-install -Sy -R https://repo-default.voidlinux.org/current -r /mnt \
		base-system grub-x86_64-efi vim efibootmgr bash-completion curl chrony \
		git

	root_uuid=$(blkid -s UUID -o value "${device}2")
	boot_uuid=$(blkid -s UUID -o value "${device}1")

	cat > /mnt/etc/fstab <<EOF
UUID=$root_uuid / ext4 defaults 0 1
UUID=$boot_uuid /boot vfat defaults 0 2
tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
EOF

	sed '1,/^stage2()/d' "$0" > /mnt/voidvm.sh
	chmod +x /mnt/voidvm.sh
	xchroot /mnt env IN_CHROOT=1 ./voidvm.sh
}

stage2() {
	# ========================
	# part2: System configure
	# ========================
	printf '\033c'

	chown root:root /
	chmod 755 /

	echo VOID > /etc/hostname

	useradd -mG wheel sh
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
	chmod 440 /etc/sudoers.d/wheel

	cat > /etc/rc.conf <<EOF
TIMEZONE="Africa/Casablanca"
HARDWARECLOCK="UTC"
KEYMAP=fr
EOF

	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	echo "en_US.UTF-8 UTF-8" >> /etc/default/libc-locales
	xbps-reconfigure -f glibc-locales

	cat > /etc/hosts <<EOF
127.0.0.1       localhost
::1             localhost
127.0.1.1       VOID.localdomain    VOID
EOF

	sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
	sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 console=ttyS0,115200n8"|' /etc/default/grub

	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
	grub-mkconfig -o /boot/grub/grub.cfg

	echo "Reconfigure all"
	xbps-reconfigure -fa

	ln -s /etc/sv/agetty-ttyS0 /etc/runit/runsvdir/default/
	ln -s /etc/sv/agetty-tty1 /etc/runit/runsvdir/default/
	ln -s /etc/sv/dhcpcd /etc/runit/runsvdir/default/
	ln -s /etc/sv/chronyd /etc/runit/runsvdir/default/
	ln -s /etc/sv/udevd /etc/runit/runsvdir/default/

	ls -alh /etc/runit/runsvdir/default/

	root_hash=$(openssl passwd -6 'void')
	sh_hash=$(openssl passwd -6 'void')

	usermod -p "$root_hash" root
	usermod -p "$sh_hash" sh

	echo "Installation complete! Type reboot."
}

# ========================
# Script entry point
# ========================
if [ "$IN_CHROOT" = "1" ]; then
	stage2
else
	stage1
fi
