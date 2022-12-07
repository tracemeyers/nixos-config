# nixos-config

## Installer

### Networking

#### WIFI

Connect to WiFi

```
SSID=ailuj
SSID_PW='***'

# nmcli dev wifi connect $SSID password $SSID_PW
```

Test it

```
ping google.com
```

### Disk

List disks

```
# lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nvme0n1     259:0    0 238.5G  0 disk 
├─nvme0n1p1 259:1    0   300M  0 part /boot/efi
├─nvme0n1p2 259:2    0 225.7G  0 part /
└─nvme0n1p3 259:3    0  12.4G  0 part [SWAP]
```

#### Parition

List disks

```
lsblk

DISK_PATH=/dev/nvme0n1
SWAP_SIZE=80GB
```

Create a GPT partition table.

```
# parted $DISK_PATH -- mklabel gpt
```

Add the root partition. This will fill the disk except for the end part, where the swap will live, and the space left in front (512MiB) which will be used by the boot partition.

```
# parted $DISK_PATH -- mkpart primary 512MB -$SWAP_SIZE
```

Next, add a swap partition. The size required will vary according to needs.

```
# parted $DISK_PATH -- mkpart primary linux-swap -$SWAP_SIZE 100%
```

Finally, the boot partition. NixOS by default uses the ESP (EFI system partition) as its /boot partition. It uses the initially reserved 512MiB at the start of the disk.

```
# parted $DISK_PATH -- mkpart ESP fat32 1MB 512MB
# parted $DISK_PATH -- set 3 esp on
```

Refer to the new disk layout

```
lsblk $DISK_PATH
```

Create the primary partition's filesystem

```
# mkfs.ext4 -L nixos ${DISK_PATH}p1
```

Create the swap

```
# mkswap -L swap ${DISK_PATH}p2
```

Create the UEFI boot partition

```
# mkfs.fat -F 32 -n boot ${DISK_PATH}p3
```

### Install

Mount the partitions previously created:

```
# mount /dev/disk/by-label/nixos /mnt
#
# mkdir -p /mnt/boot
# mount /dev/disk/by-label/boot /mnt/boot
#
# swapon /dev/disk/by-label/swap
```

Generate the initial config:

```
# nixos-generate-config --root /mnt
```
