#!/usr/bin/env bash

# This is stage 2 after installing the system, where all the necessary setup
# tasks are handled automatically instead of manually.

# NOTE: Don't run this script as root or in the root user.
set -euo pipefail

# Get the Hostname (DEB, FREE_BSD, ARCH, VOID, ALPINE)
if command -v hostnamectl >/dev/null 2>&1; then
	HOSTNAME=$(hostnamectl --static)
elif command -v hostname >/dev/null 2>&1; then
	HOSTNAME=$(hostname)
else
	HOSTNAME=$(cat /etc/hostname)
fi

# Common packages (same name on all systems)
COMMON_PKG=(git bat lsd yt-dlp fzf tmux fontconfig htop xclip xdotool ffmpeg \
	aria2 chafa tree dnsmasq sakura jq python3 vim curl bash bash-completion \
	alsa-utils llvm wget fastfetch rsync shellcheck diffoscope strace valgrind \
	less)

LINUX_PKG=(rtmpdump time ranger clang nodejs parted udftools cmake)

NOT_COMMON_PKG=(go st terminus-font)


# ARCH
##

if [[ "$HOSTNAME" == *"ARCH"* ]]; then
	echo "Detected Arch Linux system ($HOSTNAME)"

	sudo reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

	echo
	sudo tee /etc/resolv.conf > /dev/null <<EOF
	nameserver 1.1.1.1
	nameserver 8.8.8.8
EOF

echo
sudo sed -i '/^OPTIONS=/ s/\<debug\>/!debug/' /etc/makepkg.conf

echo
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git go base-devel

echo
printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin %s --keep-baud 115200,38400,9600 %%I \$TERM\n" "$(whoami)" | sudo systemctl edit serial-getty@ttyS0.service --stdin
cat /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf

echo
echo "Installing YAY"
cd /tmp/
[ -d yay ] && rm -rf yay
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
cd ~

echo
echo "Updating the System"
yay -Syu --noconfirm

echo "Installing some packages"
echo
yay -S --noconfirm imagemagick noto-fonts noto-fonts-{cjk,emoji,extra} namcap \
	"${COMMON_PKG[@]}" "${NOT_COMMON_PKG[@]}" "${LINUX_PKG[@]}" devtools \
	python-pytest git-delta sshfs paccache-hook mlocate nasm

echo
sudo sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect modconf block filesystems fsck)/' /etc/mkinitcpio.conf

echo
sudo sed -i \
	-e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/" \
	-e 's/^fallback_image/#fallback_image/' \
	-e 's/^fallback_uki/#fallback_uki/' \
	-e 's/^fallback_options/#fallback_options/' \
	/etc/mkinitcpio.d/linux-lts.preset

echo
sudo tee /etc/xdg/reflector/reflector.conf > /dev/null <<EOF
--protocol https
--latest 20
--sort rate
--age 12
--country Germany,France,Netherlands,Spain,Portugal,Morocco
--save /etc/pacman.d/mirrorlist
--download-timeout 5
--connection-timeout 5
EOF

echo "Installing Other Packages"
sleep 2s
cd /tmp/ && wget https://raw.githubusercontent.com/elbachir-one/svt/refs/heads/main/archPkgList.txt
cd
echo
yay -S --noconfirm --needed - < /tmp/archPkgList.txt

echo
sudo mkinitcpio -P

echo
yay -Sc --noconfirm

echo
tee ~/.bash_aliases > /dev/null <<EOF
alias q='yay -Ss'
alias u='yay -Syu --noconfirm && yay -Sc --noconfirm && sudo mkinitcpio -P -v'
alias i='yay -S --noconfirm'
alias c='yay -Sc --noconfirm'
alias d='yay -Rns'
alias mk='sudo mkinitcpio -P -v'
EOF


# VOID
##

elif [[ "$HOSTNAME" == *"VOID"* ]]; then
	echo "Detected Void Linux system ($HOSTNAME)"

	sudo sed -i "/^GETTY_ARGS=/c\GETTY_ARGS=\" --noclear --autologin $(whoami)\"" /etc/runit/runsvdir/current/agetty-ttyS0/conf
	echo
	cat /etc/runit/runsvdir/current/agetty-ttyS0/conf

	sudo tee /etc/xbps.d/ignore.conf > /dev/null <<EOF
ignorepkg=linux-firmware-amd
ignorepkg=linux-firmware-nvidia
ignorepkg=linux-firmware-intel
ignorepkg=linux-firmware-network
ignorepkg=linux-firmware-broadcom
ignorepkg=wpa_supplicant
ignorepkg=linux6.12
ignorepkg=linux-headers
ignorepkg=btrfs-progs
EOF

sudo xbps-remove -Ry linux-firmware-{amd,nvidia,intel,network,broadcom} \
	wpa_supplicant linux6.12 linux-headers

sudo touch /etc/sv/agetty-tty{2,3,4,5,6}/down

sudo rm /var/service/agetty-tty{2,3,4,5,6}
echo

echo "Updating the System"
echo
sudo xbps-install -S
sudo xbps-install -uy xbps
sudo xbps-install -Suy

sudo xbps-install -Sy base-devel ImageMagick libXft-devel libxkbcommon-tools \
	linux-lts linux-lts-headers harfbuzz-devel "${COMMON_PKG[@]}" delta \
	"${NOT_COMMON_PKG[@]}" "${LINUX_PKG[@]}" fuse-sshfs nasm

echo "Reconfiguring All"
echo
sudo xbps-reconfigure -fa

echo
sudo rm /boot/vmlinuz-6.12.*
sudo rm /boot/config-6.12.*

echo
echo
sudo tee /etc/default/grub > /dev/null <<EOF
#
# Configuration file for GRUB.
#
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR="Void"
GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0,115200"
EOF

echo
sudo chmod -x /etc/grub.d/30_os-prober

echo
sudo rm /var/cache/xbps/*

echo
sudo tee /etc/dracut.conf.d/omit.conf > /dev/null <<EOF
	omit_dracutmodules+=" resume kernel-modules-extra crypt hwdb nvdimm usrmount terminfo shell-interpreter i18n btrfs qemu "
EOF
sudo dracut -f
echo

sudo grub-mkconfig -o /boot/grub/grub.cfg
echo

sudo vkpurge rm all
echo

tee ~/.bash_aliases > /dev/null <<EOF
alias q='xbps-query -Rs'
alias u='sudo xbps-install -Suy && sudo xbps-reconfigure -fa'
alias i='sudo xbps-install -S'
alias c='sudo xbps-remove -oy && sudo xbps-remove -Oy && sudo vkpurge rm all'
alias d='sudo xbps-remove -R'
alias dmesg='dmesg --color=always'
EOF

echo "Clone Void Packages"
cd ~ && git clone --depth=1 https://github.com/void-linux/void-packages
cd void-packages/ && ./xbps-src binary-bootstrap

tee ~/void-packages/etc/conf > /dev/null <<EOF
XBPS_ALLOW_RESTRICTED=yes
XBPS_MAKEJOBS=2
EOF


# DEBIAN
##

elif [[ "$HOSTNAME" == *"DEB"* ]]; then
	echo "Detected Debian system ($HOSTNAME)"

	echo
	printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin %s --keep-baud 115200,38400,9600 %%I \$TERM\n" "$(whoami)" | sudo systemctl edit serial-getty@ttyS0.service --stdin
	cat /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf

	echo
	sudo apt update && sudo apt -y upgrade
	sudo apt install -y build-essential imagemagick libxft-dev fonts-font-awesome \
		libxkbcommon-dev fonts-noto-cjk fonts-noto-color-emoji fonts-terminus \
		stterm golang "${COMMON_PKG[@]}" "${LINUX_PKG[@]}" git-delta sshfs

	echo
	sudo tee /etc/default/grub > /dev/null <<EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR="Debian"
GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS,115200"
GRUB_CMDLINE_LINUX=""
EOF

echo
sudo update-initramfs -u -v
sudo chmod -x /etc/grub.d/30_os-prober
sudo update-grub

echo
tee ~/.bash_aliases > /dev/null <<EOF
alias q='apt search'
alias u='sudo apt update && sudo apt -y upgrade && sudo update-initramfs -uv && sudo apt autoremove -y && sudo apt clean'
alias i='sudo apt install -y'
alias c='sudo apt autoremove -y && sudo apt clean'
alias d='sudo apt remove --purge -y'
EOF


# ALPINE
## Before running the script, uncomment the second line for the APK repositories,
## set up passwordless sudo, and install bash and make it the default shell.

elif [[ "$HOSTNAME" == *"ALPINE"* ]]; then
	echo "Detected Alpine Linux system ($HOSTNAME)"

	sudo tee /etc/default/grub > /dev/null <<EOF
GRUB_TIMEOUT=0
GRUB_DISABLE_SUBMENU=y
GRUB_DISABLE_RECOVERY=true
GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0,115200 modules=sd-mod,usb-storage,ext4 rootfstype=ext4"
EOF

echo
sudo chmod -x /etc/grub.d/30_os-prober

echo
sudo apk update && sudo apk upgrade

echo
sudo apk add build-base pulseaudio imagemagick font-noto-{cjk,emoji} delta \
	"${COMMON_PKG[@]}" "${NOT_COMMON_PKG[@]}" "${LINUX_PKG[@]}" sshfs

echo
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo
sudo tee /usr/sbin/autologin > /dev/null <<EOF
#!/bin/sh
exec login -f sh
EOF

echo
sudo chmod +x /usr/sbin/autologin

sudo tee /etc/inittab > /dev/null <<EOF
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default

tty1::respawn:/sbin/getty 38400 tty1
ttyS0::respawn:/sbin/getty -L 115200 -n -l /usr/sbin/autologin ttyS0 vt100

::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/openrc shutdown
EOF
echo

sudo sed -i 's|^root:x:0:0:root:/root:/bin/sh$|root:x:0:0:root:/root:/bin/bash|' /etc/passwd
sudo sed -i 's|^sh:x:1000:1000:sh:/home/sh:/bin/sh$|sh:x:1000:1000:sh:/home/sh:/bin/bash|' /etc/passwd
echo

sudo tee /etc/apk/repositories > /dev/null <<EOF
#/media/cdrom/apks
http://mirror.marwan.ma/alpine/edge/main
http://mirror.marwan.ma/alpine/edge/community
http://mirror.marwan.ma/alpine/edge/testing
EOF

tee ~/.bash_aliases > /dev/null <<EOF
alias q='apk search'
alias u='sudo apk update && sudo apk upgrade'
alias i='sudo apk add'
alias c='sudo apk cache clean'
alias d='sudo apk del'
EOF


# ARTIX
#
elif [[ "$HOSTNAME" == *"ARTIX"* ]]; then
	echo "Detected Artix Linux system ($HOSTNAME)"

	echo
	sudo tee /run/NetworkManager/resolv.conf >> /dev/null <<EOF
	nameserver 1.1.1.1
	nameserver 8.8.8.8
EOF

echo
sudo sed -i '/^OPTIONS=/ s/\<debug\>/!debug/' /etc/makepkg.conf

echo
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git go base-devel

echo
echo "Installing YAY"
cd /tmp/
[ -d yay ] && rm -rf yay
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
cd ~

echo
echo "Updating the System"
yay -Syu --noconfirm

echo "Installing some packages"
echo
yay -S --noconfirm imagemagick noto-fonts noto-fonts-{cjk,emoji,extra} namcap \
	"${COMMON_PKG[@]}" "${NOT_COMMON_PKG[@]}" "${LINUX_PKG[@]}" python-pytest \
	sshfs

echo
sudo sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect modconf block filesystems fsck)/' /etc/mkinitcpio.conf

echo
sudo sed -i \
	-e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/" \
	-e 's/^fallback_image/#fallback_image/' \
	-e 's/^fallback_uki/#fallback_uki/' \
	-e 's/^fallback_options/#fallback_options/' \
	/etc/mkinitcpio.d/linux-lts.preset

echo
sudo mkinitcpio -P

echo
yay -Sc --noconfirm

echo
tee ~/.bash_aliases > /dev/null <<EOF
alias q='yay -Ss'
alias u='yay -Syu --noconfirm && yay -Sc --noconfirm && sudo mkinitcpio -P'
alias i='yay -S --noconfirm'
alias c='yay -Sc --noconfirm'
alias d='yay -Rns'
alias mk='sudo mkinitcpio -P -v'
EOF


# FREE BSD
## Before all you need to login as root and install (bash, sudo)
## After that change the shell (chsh -s bash username).
## And also add the user to the sudo file.

elif [[ "$HOSTNAME" == *"FREE_BSD"* ]]; then
	echo "Detected FreeBSD system ($HOSTNAME)"

	echo
	sudo pkg update && sudo pkg upgrade

	echo
	sudo pkg install -y ImageMagick7 libXft font-awesome libXkbcommon noto-{extra,emoji} \
		"${COMMON_PKG[@]}" "${NOT_COMMON_PKG[@]}" npm nnn python valgrind git-delta \
		sshfs

	echo
	sudo tee /boot/loader.conf > /dev/null <<EOF
autoboot_delay="-1"
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="comconsole,vidconsole"
EOF

echo
sudo tee -a /etc/gettytab > /dev/null <<'EOF'
al|Autologin over serial:\
	   :al=sh:tc=3wire.9600:
EOF

echo
sudo tee /etc/ttys > /dev/null <<EOF
	ttyv0   "/usr/libexec/getty Pc"     xterm   onifexists secure
	ttyu0   "/usr/libexec/getty al"     vt100   onifconsole secure
EOF

echo
tee ~/.bash_aliases > /dev/null <<'EOF'
[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && \
		source /usr/local/share/bash-completion/bash_completion.sh

alias q='pkg search'
alias u='sudo pkg update && sudo pkg upgrade -y'
alias i='sudo pkg install -y'
alias c='sudo pkg clean -y'
EOF

else
	echo "Unknown hostname ($HOSTNAME). Please name it ARCH* or VOID*."
	exit 1
fi

echo
echo "Setup of GRC"
cd /tmp/
[ -d grc ] && rm -rf grc
git clone --depth=1 https://github.com/garabik/grc.git && cd grc/
sudo ./install.sh && sudo cp /etc/profile.d/grc.sh /etc/
cd

echo
echo "DNS Setup"
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

echo
echo "Dotfiles Setup"
DOTFILES_REPO="https://github.com/elbachir-one/svt"
DOTFILES_CLONE="$HOME/.dotfiles"
DOTFILES_STORE="$HOME/.file"

rm -rf "$DOTFILES_CLONE"
git clone --depth=1 "$DOTFILES_REPO" "$DOTFILES_CLONE"

rm -rf "$DOTFILES_STORE"
mkdir -p "$DOTFILES_STORE"
cp -rf "$DOTFILES_CLONE/configfiles/." "$DOTFILES_STORE/"

rm -rf "$DOTFILES_CLONE"

cd "$HOME"
for file in "$DOTFILES_STORE"/.* "$DOTFILES_STORE"/*; do
	[ -e "$file" ] || continue

	fname=$(basename "$file")
	[[ "$fname" == "." || "$fname" == ".." ]] && continue

	target="$HOME/$fname"
	source=".file/$fname"

	if [ -e "$target" ] || [ -L "$target" ]; then
		rm -rf "$target"
	fi

	ln -s "$source" "$fname"
done

echo
echo "Setup complete for $HOSTNAME. You can reboot now, or the system will automatically reboot in 30 seconds."
echo
sleep 5

sudo reboot
