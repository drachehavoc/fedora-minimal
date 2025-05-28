#!/bin/bash

# ###################################################################################################### #
# ###                                                                                                ### #
# ### CHECK PERMISSIONS                                                                              ### #
# ###                                                                                                ### #
# ###################################################################################################### #

if ! {                        \
  [ "$(id -u)" -eq 0 ] &&     \
  [ -n "$SUDO_USER" ]  &&     \
  [ "$SUDO_USER" != "root" ]; \
}; then
  echo "ERRO | Este script deve ser executado por um usuário comum usando 'sudo'."
  echo "     | Exemplo: usuario_comum$ sudo $0"
  echo "     | Não execute diretamente como root ou usando 'sudo' quando já logado como root."
  exit 1
fi

# ###################################################################################################### #
# ###                                                                                                ### #
# ### UPDATE & UPGRADE                                                                               ### #
# ###                                                                                                ### #
# ###################################################################################################### #

dnf upgrade -y
dnf update -y

# ###################################################################################################### #
# ###                                                                                                ### #
# ### FUNCTIONS                                                                                      ### #
# ###                                                                                                ### #
# ###################################################################################################### #

# executa como usuário que chamou o sudo
runas() {
  sudo -H -u "$SUDO_USER" -- "$@"
  return $?
}

# gsettings sem sessão iniciada para usuário 
gset() {
  runas dbus-run-session gsettings "$@" 
}

# ###################################################################################################### #
# ###                                                                                                ### #
# ### DEFINE PACKAGES TO INSTALL                                                                     ### #
# ###                                                                                                ### #
# ###################################################################################################### #

# apps instaled in the host
host_apps=(
  # gnome
  gdm
  gnome-shell
  gnome-terminal
  # gnome extensions
  gnome-shell-extension-just-perfection
  gnome-shell-extension-blur-my-shell
  # gnome apps
  nautilus
  nautilus-open-terminal
  # fonts
  adobe-source-code-pro-fonts
  google-noto-sans-cjk-ttc-fonts
  google-noto-emoji-color-fonts
  # other apps
  flatpak
  distrobox
)

# apps flatpack
flatpack_apps=(
  org.gnome.Totem
  org.gnome.Loupe
)

# ###################################################################################################### #
# ###                                                                                                ### #
# ### CONFIG PACKAGE MANAGER                                                                         ### #
# ###                                                                                                ### #
# ###################################################################################################### #

# backup dnf.conf
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak

# replace dnf.conf
cat << 'EOF' > /etc/dnf/dnf.conf
[main]
max_parallel_downloads=15
installonly_limit=10
install_weak_deps=False
#fastestmirror=True
deltarpm=True
EOF

# ###################################################################################################### #
# ###                                                                                                ### #
# ### INSTALL PACKAGES                                                                               ### #
# ###                                                                                                ### #
# ###################################################################################################### #

dnf install -y ${host_apps[@]}

# ###################################################################################################### #
# ###                                                                                                ### #
# ### ADD REPOSITORIES                                                                               ### #
# ###                                                                                                ### #
# ###################################################################################################### #

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
runas flatpak install flathub -y ${flatpack_apps[@]}

# ###################################################################################################### #
# ###                                                                                                ### #
# ### CONFIG GNOME SHELL                                                                             ### #
# ###                                                                                                ### #
# ###################################################################################################### #

# dark mode
gset set org.gnome.desktop.interface  color-scheme  "prefer-dark"
gset set org.gnome.desktop.interface  gtk-theme     "Adwaita-dark"
gset set org.gnome.desktop.background primary-color "#2c3e50"
gset set org.gnome.desktop.interface  accent-color  "purple"

# shortcuts
gset set org.gnome.desktop.wm.keybindings switch-applications          "[]"
gset set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
gset set org.gnome.desktop.wm.keybindings switch-windows               "['<Alt>Tab']"
gset set org.gnome.desktop.wm.keybindings switch-windows-backward      "['<Shift><Alt>Tab']"

# exteção just-perfection: meu estilo da extensão
gset set org.gnome.shell.extensions.just-perfection panel                          "false"
gset set org.gnome.shell.extensions.just-perfection dash-icon-size                 "32"
gset set org.gnome.shell.extensions.just-perfection dash-separator                 "false"
gset set org.gnome.shell.extensions.just-perfection workspace-switcher-should-show "false"
gset set org.gnome.shell.extensions.just-perfection search                         "false"
gset set org.gnome.shell.extensions.just-perfection panel-in-overview              "true"

# IMORALIDADE: isso não mostra a mensagem de pedido de apoio
#              NÃO FAÇA ISSO EM PRODUÇÂO, DOE! para o projeto just-perfection 
gset set org.gnome.shell.extensions.just-perfection support-notifier-showed-version "999"

# muda o formato de hora para 24hrs
gset set org.gnome.desktop.interface clock-format "24h"

# habilita a extensões para o gnome
gset set org.gnome.shell enabled-extensions "['just-perfection-desktop@just-perfection', 'blur-my-shell@aunetx']" 

# remove rodos os intens pinados na dash
# NÃO DESCOBRI COMO PERSISTIR ISSO
gset set org.gnome.shell favorite-apps "[]"

# remover grupos de apps
# NÃO DESCOBRI COMO PERSISTIR ISSO
gset reset-recursively org.gnome.desktop.app-folders

# listar pastas primeiro no nautilus
gset set org.gtk.gtk4.Settings.FileChooser sort-directories-first true


# ###################################################################################################### #
# ###                                                                                                ### #
# ### DISTROBOX                                                                                      ### #
# ###                                                                                                ### #
# ###################################################################################################### #

runas bash -c "distrobox create        \
  --image fedora                       \
  --name day-by-day                    \
  --hostname day-by-day                \
  --home ~/.distrobox-homes/day-by-day \
  --nvidia                             \
  --yes"

runas bash -c "distrobox create     \
  --image fedora                    \
  --name sandbox                    \
  --hostname sandbox                \
  --home ~/.distrobox-homes/sandbox \
  --no-entry                        \
  --nvidia                          \
  --yes"

# ###################################################################################################### #
# ###                                                                                                ### #
# ### DEFINE GRAPHICAL TARGET AS DEFAULT & START GDM                                                 ### #
# ###                                                                                                ### #
# ###################################################################################################### #

systemctl set-default graphical.target
systemctl start gdm
