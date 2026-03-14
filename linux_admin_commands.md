# System Administration Commands Reference

A curated collection of commands for Linux system administration, troubleshooting,
and configuration. Includes commands for Arch Linux, Debian, Hyprland,
and general desktop management.

---

## Hyprland & XWayland

### Discord Scaling Factor in Hyprland
> Force XWayland to ignore scaling factors, useful for Discord or other X apps on HiDPI displays.
```sh
xwayland {
  force_zero_scaling = true
}
```

---

## Audio & PipeWire

### Check PipeWire logs (audio issues)
> Show the last 50 log lines from the user PipeWire service to troubleshoot audio problems.
```sh
journalctl --user -xeu pipewire.service --no-pager | tail -50
```

---

## Desktop Environments (GNOME)

### Remove all GNOME extra packages
> Uninstall all packages from the `gnome-extra` group along with dependencies.
```sh
sudo pacman -Rns $(pacman -Sgq gnome-extra)
```

### Clean up GNOME or any DE
> Remove GNOME packages and find residual configuration directories.
```sh
sudo pacman -Rns gnome-browser-connector
sudo pacman -Rns gnome

# find related files
sudo find /etc -maxdepth 2 -type d \( -iname '*gnome*' -o -iname '*gdm*' \)
```

---

## Network Management

### Check if Ethernet cable is working
> Use `ethtool` to check the status of the default network interface.
```sh
ethtool $(ip route | awk '/default/ {print $5}')
```

### Modify NetworkManager connection permissions
> Remove restrictions for a Wi-Fi connection.
```sh
nmcli connection modify LMT-5GHz-911C connection.permissions ""
```

### Configure systemd-networkd for Ethernet
> Setup a simple DHCP network configuration for interfaces starting with `en`.
```sh
sudo tee /etc/systemd/network/en.network > /dev/null <<EOF
[Match]
Name=en*
[Network]
DHCP=ipv4
EOF
```

### Fix limited connectivity (DNS issues)
> Ensure `/etc/resolv.conf` is a symlink and enable systemd-resolved.
```sh
ls -l /etc/resolv.conf
```
If missing:
```sh
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```
Enable and restart services:
```sh
sudo systemctl enable --now systemd-resolved
sudo systemctl restart NetworkManager
```

### Check network devices
> List PCI network and Ethernet devices with driver info.
```sh
lspci -nnk | grep -A3 Network
lspci -nnk | grep -A3 -i ethernet
```

---

## Bootloaders & EFI

### Install and configure GRUB
> Install GRUB bootloader in UEFI mode and generate its configuration.
```sh
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
```

### Setup Secure Boot for GRUB
> Install GRUB with TPM support and disable shim lock.
```sh
grub-install --target=x86_64-efi --efi-directory=esp --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
```

### Sign systemd-boot EFI binary with SBCTL
> Sign systemd-boot EFI binary for Secure Boot.
```sh
sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed \
  /usr/lib/systemd/boot/efi/systemd-bootx64.efi
```

---

## Kernel & Initramfs

### Check for Wi-Fi firmware and microcode issues
> Filter kernel messages for iwlwifi, firmware, or CPU microcode errors.
```sh
sudo dmesg -T | grep -Ei 'iwlwifi|firmware|microcode'
```

### Check initramfs for specific filesystem support
> List contents of initramfs to see if btrfs module is included.
```sh
lsinitcpio /boot/initramfs-linux.img | grep btrfs
```

### Build initramfs on Debian
> Generate a new initramfs image for the current kernel.
```sh
sudo update-initramfs -c -k $(uname -r)
```

---

## Pacman & Package Management (Arch Linux)

### Check when a package was installed
> Look for the installation date of a specific package in pacman logs.
```sh
grep "installed <pkgName>" /var/log/pacman.log
```

### Fix Pacman package conflicts
> Upgrade system and overwrite conflicting files.
```sh
pacman -Qqn | pacman --overwrite='*' -Su -
```

### Fix errors updating Pacman
> Force overwrite files while performing a full system upgrade.
```sh
sudo pacman -Syu --overwrite '*'
```

### List explicitly installed packages
> Show packages manually installed by the user.
```sh
pacman -Qeq
```

### Delete debug packages
> Remove all packages ending with `-debug`.
```sh
sudo pacman -Rs $(pacman -Qq | grep -- '-debug$')
```

### Mark packages as explicitly installed
> Tell Pacman these packages are intentional so they aren’t removed as orphans.
```sh
sudo pacman -D --asexplicit cmake go
```

---

## System Logs & Troubleshooting

### Check journal logs from a specific time
> View system logs from a given timeframe and filter by severity.
```sh
journalctl --since "5 hours ago"
journalctl --since "6 hours ago" --until "4 hours ago"
journalctl --since "5 hours ago" -p warning
journalctl --since "5 hours ago" -p err
```

### View previous boot kernel logs
> Show kernel messages from the previous boot.
```sh
journalctl -k -b -1
```

### View recent system logs with priority
> Show logs from the previous boot with priority 0–3.
```sh
journalctl -b -1 -p 0..3
```

---

## Hardware & Drivers

### Check Wi-Fi driver
> Display PCI devices and drivers related to network interfaces.
```sh
lspci -nnk | grep -iA3 net
```

### Check GPU driver
> List PCI devices related to graphics.
```sh
lspci -k | grep -A 3 -E "(VGA|3D)"
```

---

## VMware

### Rebuild VMware after system update
> Recompile VMware Workstation modules if the kernel updated.
```sh
yay -S vmware-workstation --rebuild
```

---

## Utilities

### Copy only large files with rsync
> Sync files larger than 300MB from one directory to another.
```sh
rsync -avhP --min-size=300M ./currentDir /DistDir/
```

### Generate a diff file for last two commits
> Create a patch file comparing the last two Git commits.
```sh
git diff HEAD~2 HEAD > my_two_commit_patch.diff
```

### Upload command output to 0x0.st
> Pipe any command output to an online paste service.
```sh
curl -F 'file=@-' https://0x0.st
```

---

## Boot Splash & Display Managers

### Set up Plymouth boot splash
> Configure boot splash themes in Plymouth.
- Add `plymouth` to `mkinitcpio.conf` after `kms`
- Add `splash` to the kernel parameters
- List available themes:
```sh
plymouth-set-default-theme --list
```
- Set and enable theme:
```sh
sudo plymouth-set-default-theme <ThemeName> -R
```

### Fix SDDM black screen
> Delay SDDM start to prevent black screen issues.
```sh
sudo systemctl edit sddm.service
```
Then add:
```sh
[Service]
ExecStartPre=/bin/sleep 1
```

---
