#!/bin/sh


echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nInstalling Packages...\n"

sleep 2

sed -i 's/#Color/Color/; s/#\[multilib\]/\[multilib\]/; /\[multilib\]/{N;s/#Include/Include/}' /etc/pacman.conf

pacman -Syyu grub efibootmgr intel-ucode pacman-contrib pkgstats pkgfile neofetch htop git make xorg mesa lib32-mesa intel-media-driver libva-intel-driver lib32-libva-intel-driver libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau xf86-video-amdgpu vulkan-icd-loader lib32-vulkan-icd-loader vulkan-intel lib32-vulkan-intel vulkan-radeon lib32-vulkan-radeon amdvlk lib32-amdvlk plasma-meta kde-applications-meta kdepim-addons telepathy telepathy-kde-meta packagekit-qt5 fwupd ffmpeg gst-libav gst-plugins-base lib32-gst-plugins-base gst-plugins-good lib32-gst-plugins-good gst-plugins-bad gst-plugins-ugly libde265 gstreamer-vaapi ttf-dejavu ttf-liberation ttf-droid gnu-free-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-roboto ttf-ubuntu-font-family ttf-opensans cantarell-fonts inter-font wqy-microhei wqy-zenhei wqy-bitmapfont otf-ipafont cpupower haveged android-tools hunspell hunspell-en_US xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-kde libappindicator-gtk2 libappindicator-gtk3 lib32-libappindicator-gtk2 lib32-libappindicator-gtk3 zsh zsh-doc grml-zsh-config zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting zsh-lovers zsh-theme-powerlevel10k powerline

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nSetting Localtime...\n"

sleep 2

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

hwclock --systohc

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nConfiguring Locale...\n"

sleep 2

sed -i 's/#en_US.UTF-8/en_US.UTF-8/; s/#en_IN/en_IN/' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo "laptop" >> /etc/hostname

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nAccount Management...\n"

sleep 2

echo -e "\nEnter Password for ROOT\n"

passwd root

echo -e "\nCreating New User...\n"

useradd -m -G wheel -s /bin/zsh ron

echo -e "\nEnter Password for New User\n"

passwd ron

echo -e "root ALL=(ALL) NOPASSWD: ALL\n%wheel ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/00_nopasswd

cat << EOT >> /etc/polkit-1/rules.d/49-nopasswd_global.rules
/* Allow members of the wheel group to execute any actions
 * without password authentication, similar to "sudo NOPASSWD:"
 */
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOT

cat << EOT >> /etc/polkit-1/rules.d/50-udisks.rules
// Original rules: https://github.com/coldfix/udiskie/wiki/Permissions
// Changes: Added org.freedesktop.udisks2.filesystem-mount-system, as this is used by Dolphin.

polkit.addRule(function(action, subject) {
  var YES = polkit.Result.YES;
  // NOTE: there must be a comma at the end of each line except for the last:
  var permission = {
    // required for udisks1:
    "org.freedesktop.udisks.filesystem-mount": YES,
    "org.freedesktop.udisks.luks-unlock": YES,
    "org.freedesktop.udisks.drive-eject": YES,
    "org.freedesktop.udisks.drive-detach": YES,
    // required for udisks2:
    "org.freedesktop.udisks2.filesystem-mount": YES,
    "org.freedesktop.udisks2.encrypted-unlock": YES,
    "org.freedesktop.udisks2.eject-media": YES,
    "org.freedesktop.udisks2.power-off-drive": YES,
    // Dolphin specific
    "org.freedesktop.udisks2.filesystem-mount-system": YES,
    // required for udisks2 if using udiskie from another seat (e.g. systemd):
    "org.freedesktop.udisks2.filesystem-mount-other-seat": YES,
    "org.freedesktop.udisks2.filesystem-unmount-others": YES,
    "org.freedesktop.udisks2.encrypted-unlock-other-seat": YES,
    "org.freedesktop.udisks2.eject-media-other-seat": YES,
    "org.freedesktop.udisks2.power-off-drive-other-seat": YES
  };
  if (subject.isInGroup("storage")) {
    return permission[action.id];
  }
});
EOT

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nConfiguring AUR...\n"

sleep 2

sudo -u ron mkdir /home/ron/AUR/

cd /home/ron/AUR/

sudo -u ron git clone https://aur.archlinux.org/yay-bin.git

cd ./yay-bin

sudo -u ron makepkg -si --noconfirm

sudo -u ron yay -Syyu --noconfirm

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nConfiguring Bootloader...\n"

sleep 2

mkinitcpio -P

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nConfiguring Plymouth...\n"

sleep 2

sudo -u ron yay -S --noconfirm plymouth

sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT/ s/".*"/"quiet splash loglevel=3 vga=current rd.systemd.show_status=auto rd.udev.log_priority=3 vt.global_cursor_default=0 i915.fastboot=1"/' /etc/default/grub

sed -i '/\$message/ s/^/#/' /etc/grub.d/10_linux

touch /home/ron/.hushlogin

echo "kernel.printk = 3 3 3 3" >> /etc/sysctl.d/20-quiet-printk.conf

mkdir /etc/systemd/system/getty@tty1.service.d/

cat << EOT >> /etc/systemd/system/getty@tty1.service.d/skip-prompt.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin username --noclear %I $TERM
EOT

sed -i '/^MODULES/ s/(.*)/(i915)/' /etc/mkinitcpio.conf

sed -i '/^HOOKS/ s/udev/systemd sd-plymouth/' /etc/mkinitcpio.conf

mkinitcpio -P

sed -i '/^ExecStart*/aStandardOutput=null\nStandardError=journal+console' /usr/lib/systemd/system/systemd-fsck*

plymouth-set-default-theme -R bgrt

grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nFinishing Touch...\n"

sleep 2

systemctl enable sddm-plymouth NetworkManager dhcpcd dnsmasq bluetooth cpupower haveged

pkgfile --update

appstreamcli refresh-cache --force --verbose

echo -e "\nFinally Done.\n\n"

sleep 2

exit
