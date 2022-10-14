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
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo $HOSTNAME >> /etc/hostname
passwd

useradd -mG wheel $USERNAME
passwd $USERNAME

pacman -Syy
pacman -S networkmanager grub efibootmgr os-prober neofetch qtile gtk3 git alacritty
systemctl enable NetworkManager
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..

grub-install --target=x86_64-efi --efi-directory=efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg