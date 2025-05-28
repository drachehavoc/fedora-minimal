#!/bin/bash

# ###################################################################################################### #
# ###                                                                                                ### #
# ### CHECK PERMISSIONS                                                                              ### #
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
# ###################################################################################################### #

dnf upgrade -y
dnf update -y

# ###################################################################################################### #
# ###                                                                                                ### #
# ### FUNCTIONS                                                                                      ### #
# ###################################################################################################### #

### executa como usuário que chamou o sudo
runas() {
  sudo -H -u "$SUDO_USER" -- "$@"
  return $?
}

### gsettings sem sessão iniciada para usuário 
gset() {
  runas dbus-run-session gsettings "$@" 
}

# ###################################################################################################### #
# ###                                                                                                ### #
# ### DEFINE PACKAGES TO INSTALL                                                                     ### #
# ###################################################################################################### #

### apps instaled in the host
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

### apps flatpack
flatpack_apps=(
  org.gnome.Totem
  org.gnome.Loupe
)

# ###################################################################################################### #
# ###                                                                                                ### #
# ### CONFIG PACKAGE MANAGER                                                                         ### #
# ###################################################################################################### #

### backup dnf.conf
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak

### replace dnf.conf
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
# ###################################################################################################### #

dnf install -y ${host_apps[@]}

# ###################################################################################################### #
# ###                                                                                                ### #
# ### ADD REPOSITORIES                                                                               ### #
# ###################################################################################################### #

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
runas flatpak install flathub -y ${flatpack_apps[@]}

# ###################################################################################################### #
# ###                                                                                                ### #
# ### CONFIG GNOME SHELL                                                                             ### #
# ###################################################################################################### #

### prepare folder to config
mkdir -p /etc/dconf/db/local.d/

### default customizations
cat << 'EOF' > /etc/dconf/db/local.d/01-varela-customizations.conf
[org/gnome/desktop/app-folders]
folder-children=[] # @todo: não eta funcionando, depois que inicia a primeira sessão o gnome aperece com as pastas de programas

[org/gtk/gtk4/Settings/FileChooser]
sort-directories-first=true # @ não esta funcionando, quando a sessão inicia as pastas não

[org/gnome/shell]
favorite-apps=[]

[org/gnome/desktop/interface]
color-scheme="prefer-dark"
gtk-theme="Adwaita-dark"
accent-color="purple"
clock-format="24h"

[org/gnome/desktop/background]
primary-color="#2c3e50"

[org/gnome/desktop/wm/keybindings]
switch-applications="[]"
switch-applications-backward="[]"
switch-windows="['<Alt>Tab']"
switch-windows-backward="['<Shift><Alt>Tab']"

[org/gnome/shell/extensions/just-perfection]
panel=false
dash-icon-size=32
dash-separator=false
workspace-switcher-should-show=false
search=false
panel-in-overview=true
support-notifier-showed-version="999" # IMORALIDADE | isso desabilita a mensagem de pedido de financiamentodo projeto; 
                                      #             | NÃO FAÇA ISSO EM PRODUÇÂO DOE! para o projeto just-perfection

[org/gnome/shell]
enabled-extensions="['just-perfection-desktop@just-perfection', 'blur-my-shell@aunetx']"
EOF

### update dconf db
dconf update

# ###################################################################################################### #
# ###                                                                                                ### #
# ### DISTROBOX                                                                                      ### #
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
# ###################################################################################################### #

systemctl set-default graphical.target
systemctl start gdm
