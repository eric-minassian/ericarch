#!/bin/bash

lsblk
echo Enter Disk:
read DISK

echo Enter Swap Size:
read SWAP

echo Partition Drives Y-Yes N-No:
read PARTITION

echo Enter Username:
read USERNAME

echo Enter Password:
read PASSWORD

echo Enter Hostname:
read HOSTNAME

# Start Install
timedatectl set-ntp true


if [ $PARTITION = "Y" ]
then
    # Create Partitions
    sgdisk --zap-all "$DISK"
    sgdisk -n 1::+512M -t 1:ef00 -c 1:EFI "$DISK"
    sgdisk -n 2::+"$SWAP" -t 2:8200 -c 2:SWAP "$DISK"
    sgdisk -n 3 -t 3:8300 -c 3:ROOT "$DISK"

    # Format Partitions
    mkfs.btrfs $DISK"3" -f
    mkswap $DISK"2"
    mkfs.fat -F 32 $DISK"1"

    # Mount Drives
    mount $DISK"3" /mnt
    mkdir /mnt/efi
    mount $DISK"1" /mnt/efi
    swapon $DISK"2"
fi

pacstrap -K /mnt base base-devel linux linux-firmware neovim

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt sed -i 's/#en_US/en_US/' /etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo $HOSTNAME > /mnt/etc/hostname
cat > /mnt/etc/hosts <<HOSTS
127.0.0.1      localhost
::1            localhost
127.0.1.1      $HOSTNAME.localdomain     $HOSTNAME
HOSTS


# Setup New User
arch-chroot /mnt useradd -mG wheel $USERNAME
arch-chroot /mnt echo $USERNAME":"$PASSWORD | chpasswd
arch-chroot /mnt sed -i 's/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Setup Bootloader and Network
arch-chroot /mnt pacman -Syy
arch-chroot /mnt pacman -S networkmanager grub efibootmgr os-prober --noconfirm
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

arch-chroot /mnt passwd -l root

umount -R /mnt
reboot
