#!/bin/bash

set -xeuo pipefail

#Add GTK4 Layer-shell Devel, for al gore
dnf -y install \
	gtk4-layer-shell-devel

install -d /usr/share/zirconium/

#install terra stuff
dnf config-manager setopt terra.enabled=1
dnf5 -y install \
    maple-fonts \
    xdg-terminal-exec-nautilus \
	iio-niri \
	valent \
	--enablerepo=terra

dnf -y copr enable yalter/niri-git
dnf -y copr disable yalter/niri-git
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo
dnf -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri-git \
    install --setopt=install_weak_deps=False \
    niri
rm -rf /usr/share/doc/niri

dnf -y copr enable avengemedia/danklinux
dnf -y copr disable avengemedia/danklinux
dnf -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux install quickshell-git

#Bazzite uses HHD, which conflicts. When Bazzite switches from HHD, we shouldn't need to install it here anyway.

#dnf -y copr enable shadowblip/InputPlumber
#dnf -y copr disable shadowblip/InputPlumber
# FIXME: remove once https://github.com/ShadowBlip/InputPlumber/pull/481 is merged and published to COPR
#dnf -y --enablerepo copr:copr.fedorainfracloud.org:shadowblip:InputPlumber \
#    install --setopt=install_weak_deps=False \
#    inputplumber || true
#inputplumber --version | grep -E -e "inputplumber [[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*"

dnf -y copr enable avengemedia/dms-git
dnf -y copr disable avengemedia/dms-git
dnf -y \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms-git \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux \
    install --setopt=install_weak_deps=False \
    dms \
    dms-cli \
    dgop \
    dsearch
install -Dpm0644 -t /usr/lib/pam.d/ /usr/share/quickshell/dms/assets/pam/* # Fixes long loging times on fingerprint auth


dnf -y \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms-git \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux \
    install --setopt=install_weak_deps=False \
    dms-greeter

# adding gamescope session without using a bazzite deck image which has no login and is STUPID
# TODO: uhhh make sure it actually works? Prob will have to look at deck images and see if they do anything specific.
dnf5 -y copr enable pvermeer/gamescope-session-guide
dnf5 -y copr disable pvermeer/gamescope-session-guide
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:pvermeer:gamescope-session-guide install gamescope-session-guide

#TODO Fix the error when building
# Adding howdy for face unlocking
dnf copr enable ronnypfannschmidt/howdy-beta -y
dnf copr disable ronnypfannschmidt/howdy-beta -y
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:ronnypfannschmidt:howdy-beta install howdy howdy-gtk howdy-authselect
howdy-authselect enable

# Other system packages
dnf -y install \
	matugen \
    greetd \
    greetd-selinux \
    brightnessctl \
    cava \
    chezmoi \
    ddcutil \
    fastfetch \
    fcitx5-mozc \
    fcitx5-configtool \
    flatpak \
    ptyxis \
    fpaste \
    fzf \
    git-core \
    glycin-thumbnailer \
    gnome-disk-utility \
    gnome-keyring \
    gnome-keyring-pam \
    gnome-kra-ora-thumbnailer \
    adw-gtk3-theme \
    hyfetch \
    input-remapper \
    just \
    nautilus \
    nautilus-python \
    openssh-askpass \
    orca \
    pipewire \
    playerctl \
    qt6-qtmultimedia \
    steam-devices \
    udiskie \
    webp-pixbuf-loader \
    wireplumber \
    wl-clipboard \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    xdg-terminal-exec \
    xdg-user-dirs \
    xwayland-satellite \
    micro \
    oxygen-sounds \
	

# we already have a service for handling fcitx5
rm -f /usr/share/applications/fcitx5-wayland-launcher.desktop
rm -f /usr/share/applications/org.fcitx.Fcitx5*.desktop

# just breaks ostree deployments
rm -rf /usr/share/doc/just

dnf install -y --setopt=install_weak_deps=False \
    kf6-kirigami \
    qt6ct \
    plasma-breeze \
    kf6-qqc2-desktop-style \

#greetd keyring stuff
sed --sandbox -i -e '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd

# Codecs for video thumbnails on nautilus

#Negativo is already added by Bazzite
#dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
dnf config-manager setopt fedora-multimedia.enabled=0
dnf -y install --enablerepo=fedora-multimedia \
    -x PackageKit* \
    ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer

add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri udiskie.service
cat /usr/lib/systemd/user/niri.service

#Enable services
systemctl enable greetd
systemctl enable firewalld

# Sacrificed to the :steamhappy: emoji old god
dnf install -y \
    default-fonts-core-emoji \
    google-noto-color-emoji-fonts \
    google-noto-emoji-fonts \
    glibc-all-langpacks \
    default-fonts

#Remove STUPID fucking RAOP
dnf remove -y \
	pipewire-config-raop

# copy files from container to root
cp -avf "/ctx/files"/. /

systemctl enable --global chezmoi-init.service
systemctl enable --global chezmoi-update.timer
systemctl enable --global dms.service
systemctl enable --global fcitx5.service
systemctl enable --global gnome-keyring-daemon.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global iio-niri.service
systemctl enable --global udiskie.service
systemctl preset --global chezmoi-init
systemctl preset --global chezmoi-update
systemctl preset --global udiskie
systemctl enable brew-setup.service
systemctl enable flatpak-preinstall.service

# Copy wallpapers
install -Dpm0644 -t /usr/share/zirconium/skel/Pictures/Wallpapers/ /ctx/assets/wallpapers/*

fc-cache --force --really-force --system-only --verbose # recreate font-cache to pick up the added fonts

echo 'source /usr/share/zirconium/shell/pure.bash' | tee -a "/etc/bashrc"

# Theme greetd
tee /usr/lib/tmpfiles.d/99-greeter-config.conf <<'EOF'
L /var/cache/dms-greeter/settings.json - greeter greeter - /usr/share/doubutsu/dots/dot_config/DankMaterialShell/settings.json
L /var/cache/dms-greeter/session.json - greeter greeter - /usr/share/doubutsu/dots/private_dot_local/state/DankMaterialShell/session.json
L /var/cache/dms-greeter/dms-colors.json - greeter greeter - /usr/share/doubutsu/dots/dot_cache/DankMaterialShell/dms-colors.json
L /var/cache/dms-greeter/colors.json - greeter greeter - /usr/share/doubutsu/dots/dot_cache/DankMaterialShell/dms-colors.json
EOF

install -d /usr/share/bash-completion/completions /usr/share/zsh/site-functions /usr/share/fish/vendor_completions.d/
just --completions bash | sed -E 's/([\(_" ])just/\1zjust/g' > /usr/share/bash-completion/completions/zjust
just --completions zsh | sed -E 's/([\(_" ])just/\1zjust/g' > /usr/share/zsh/site-functions/_zjust
just --completions fish | sed -E 's/([\(_" ])just/\1zjust/g' > /usr/share/fish/vendor_completions.d/zjust.fish
