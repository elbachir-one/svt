# svt

### Swiss VM Toolkit

`makeVm.sh` is a Bash script for creating, managing, and launching QEMU/KVM virtual machines.
It supports quick VM setup with UEFI (OVMF), NAT networking, and serial console access by default.

**Features include:**
- Easy VM creation with interactive ISO selection
- Serial console support out of the box
- Simple start/stop management
- Listing and managing existing VMs

---

### Usage

```sh
wget -O makeVm.sh https://raw.githubusercontent.com/elbachir-one/svt/refs/heads/main/makeVm.sh
chmod +x makeVm.sh
./makeVm.sh
```

---

### Booting/Installing Different OSes via Serial Console

Most operating systems use **GRUB** as their bootloader, while others may use **Syslinux** or **systemd-boot**.
To boot an OS through the serial console, you may need to interrupt the boot process:

1. When the bootloader menu appears, press **`e`** to edit the boot entry.
2. After the `vmlinuz` line, add:
   ```
   console=ttyS0,115200
   ```
3. To continue booting:
   - In GRUB: press **Ctrl+X** (or sometimes just **Enter**)
   - In Syslinux/systemd-boot: usually just press **Enter**

This ensures the system output is redirected to the serial console,
allowing you to complete the installation through your terminal.
