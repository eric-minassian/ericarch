#!/bin/bash

lsblk
echo Enter Disk:
read DISK

echo Enter Swap Size:
read SWAP

echo Enter Username:
read USERNAME

echo Enter Password:
read PASSWORD

echo Enter Hostname:
read HOSTNAME

# Start Install
timedatectl set-ntp true

# Partition Drive
sfdisk -X gpt $DISK <<EOF
,+500M,U,
,+$SWAP,S,
,,L,
EOF

mkfs.btrfs $DISK"3" -f
mkswap $DISK"2"
mkfs.fat -F 32 $DISK"1"

mount $DISK"3" /mnt
mkdir /mnt/efi
mount $DISK"1" /mnt/efi
swapon $DISK"2"

pacstrap -K /mnt base base-devel linux linux-firmware neovim

genfstab -U /mnt >> /mnt/etc/fstab


#
curl https://raw.githubusercontent.com/eric-minassian/ericarch/main/ericarch-chroot.sh
chmod +x ericarch-chroot.sh
cp ericarch-chroot.sh /mnt/ericarch-chroot.sh
arch-chroot /mnt ./ericarch-chroot.sh
#

ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc

# echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
# echo "en_US ISO-8859-1" >> /etc/locale.gen
arch-chroot /mnt sed -i 's/^#en_US\.UTF-8/en_US\.UTF-8/' /etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo $HOSTNAME > /mnt/etc/hostname
arch-chroot /mnt echo "root:$PASSWORD" | chpasswd

arch-chroot /mnt useradd -mG wheel $USERNAME
arch-chroot /mnt echo "$USERNAME:$PASSWORD" | chpasswd

arch-chroot /mnt pacman -Syy
arch-chroot /mnt pacman -S networkmanager grub efibootmgr os-prober --noconfirm
arch-chroot /mnt systemctl enable NetworkManager
#echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
#echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
arch-chroot /mnt sed -i '#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL'
arch-chroot /mnt sed -i '#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false'

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg


umount -R /mnt
reboot