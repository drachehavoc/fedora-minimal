### GNOME ###

# install
dnf install -y \
gdm \
gnome-shell \
gnome-terminal \
nautilus \
nautilus-open-terminal \
adobe-source-code-pro-fonts

# cleanup
gnome remove -y \
gnome-tour 

# dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.shell.settings-background color-scheme 'Yaru-dark'
gsettings set org.gnome.desktop.background primary-color '#667c4d'

# shortcuts
gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"

# set graphical as default
systemctl set-default graphical.target 
