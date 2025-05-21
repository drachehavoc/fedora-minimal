#!/bin/bash

################################################################################
### GNOME                                                                    ###
################################################################################

# install
dnf install -y \
  gdm \
  gnome-shell \
  gnome-terminal \
  nautilus \
  nautilus-open-terminal \
  adobe-source-code-pro-fonts

# cleanup
dnf remove -y \
  gnome-tour 

# ATENÇAO: os comandos a seguir para "dark mode" e "shotcuts" estão sendo 
#          feitos com dconf ao invés de gsetings, porque no primeiro login 
#          ainda não temos uma sessão gráfica

# dark mode
#gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
#gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
#gsettings set org.gnome.desktop.background primary-color '#2c3e50'
#gsettings set org.gnome.desktop.interface accent-color 'purple'

dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
dconf write /org/gnome/desktop/background/primary-color "'#2c3e50'"
dconf write /org/gnome/desktop/interface/accent-color "'purple'"

# shortcuts
#gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
#gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
#gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
#gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"

dconf write /org/gnome/desktop/wm/keybindings/switch-applications "[]"
dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward "[]"
dconf write /org/gnome/desktop/wm/keybindings/switch-windows "['<Alt>Tab']"
dconf write /org/gnome/desktop/wm/keybindings/switch-windows-backward "['<Shift><Alt>Tab']"


# set graphical as default
systemctl set-default graphical.target 
