#!/bin/bash

echo Enter Username:
read USERNAME

echo Enter Hostname:
read HOSTNAME

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
pacman -S networkmanager grub efibootmgr os-prober
systemctl enable NetworkManager
systemctl enable lightdm
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg