#!/bin/bash

lsblk
echo Enter Disk:
read DISK

echo Enter Username:
read USERNAME

echo Enter Hostname:
read HOSTNAME

# Start Install
timedatectl set-ntp true
mkfs.btrfs $DISK"3"
mkswap $DISK"2"
mkfs.fat -F 32 $DISK"1"

mount $DISK"3" /mnt
mkdir /mnt/efi
mount $DISK"1" /mnt/efi
swapon $DISK"2"

pacstrap -K /mnt base base-devel linux linux-firmware neovim

genfstab -U /mnt >> /mnt/etc/fstab
cp ericarch-chroot.sh /mnt/ericarch-chroot.sh
arch-chroot /mnt ./ericarch-chroot.sh
umount -R /mnt
reboot