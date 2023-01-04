# nixos-config

## Installation

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

##### GPT

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

##### MBR

```
# parted $DISK_PATH -- mklabel msdos
```

```
# parted $DISK_PATH -- mkpart primary 1MB 100%
```

```
# parted $DISK_PATH -- set 1 boot on
```

##### Common

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

Edit the configuration.

```
# vi /mnt/etc/nixos/configuration.nix
```

Boot:
```
boot.loader.grub.devce = "/dev/vda"; # or whatever yours is
```

Network:
```
networking.hostName = "nixxy";
networking.networkmanager.enable = true;
```

Users:

```
users.users.cat = {
  isNormalUser  = true;
  home  = "/home/cat";
  description  = "cat";
  extraGroups  = [ "wheel" "networkmanager" ];
  initialPassword = "cuteoverload.com";
  #openssh.authorizedKeys.keys  = [ "ssh-dss AAAAB3Nza... alice@foobar" ];
};
```

Start the install:

```
# nixos-install
```

Set the password and reboot

### Other Options

#### Automatic Upgrades

configuration.nix:

```
system.autoUpgrade.enable = true;
```

## Common Commands

### Change to configuration.nix

```
# nixos-rebuild switch
```

### Upgrade Packages

```
nixos-rebuild switch --upgrade
```

### Add Channel

```
# nix-channel --add https://nixos.org/channels/nixos-unstable nixos
# nix-channel --update
```

## Build Your Own ISO

```
$ git clone https://github.com/NixOS/nixpkgs.git
$ cd nixpkgs/nixos
$ git switch nixos-unstable
$ nix-build -A config.system.build.isoImage -I nixos-config=modules/installer/cd-dvd/installation-cd-minimal.nix default.nix
```

Consider creating your own with a modified kernel:

```
{ pkgs, ... }:

{
  imports = [ ./installation-cd-graphical-plasma5.nix ];

  boot.kernelPackages = pkgs.linuxPackages_testing;
}
```

# Home Manager

## Install

Add the channel:

```
$ sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-22.11.tar.gz home-manager
$ sudo nix-channel --update
```

Add it to your configuration.nix

```
imports = [
  	...
	<home-manager/nixos>
];

[...]

home-manager.users.cat = { pkgs, ... }: {
  home.stateVersion = "22.11"; # REQUIRED!
  home.packages = with pkgs; [
    git
    # ...
  ];
  programs.bash.enable = true;
};

home-manager.useUserPackages = true;
```

Switch to it:

```
$ sudo nixos-rebuild switch
```

Check if `home-manager` is in your path.
* At some point I had to do a `nix-shell '<home-manager>' -A install`...this doesn't exist in the nixos module install instructions. I assume it was user error, but just in case...

Edit `~/.config/nixpkgs/home.nix`

```
{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cat";
  home.homeDirectory = "/home/cat";

  # Packages that should be installed to the user profile.
  home.packages = [
    pkgs.htop
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraConfig = "lua << EOF\n" + builtins.readFile ./init.lua + "\nEOF";
    plugins = with pkgs.vimPlugins; [
    ]
  };
}
```

Then run

```
$ home-manager switch
```
