#!/bin/bash

# ############################################################################################ #
# ### VERIFICAR USUÁRIOS                                                                   ### #
# ############################################################################################ #

# 1. Verificar se o script está sendo executado com privilégios de root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERRO: Este script precisa ser executado com privilégios de root."
  echo "      Por favor, use 'sudo $0'"
  exit 1
fi

# 2. Verificar se o script foi invocado por um usuário comum via sudo,
#    e não diretamente pelo usuário root ou por 'root' usando sudo.
#    A variável SUDO_USER contém o nome do usuário que invocou sudo.
#    Se SUDO_USER estiver vazia, significa que não foi via sudo (login root direto).
#    Se SUDO_USER for "root", significa que o usuário root usou 'sudo ./script.sh'.
if [ -z "$SUDO_USER" ] || [ "$SUDO_USER" == "root" ]; then
  echo "ERRO: Este script deve ser executado por um usuário comum usando 'sudo'."
  echo "      Não execute diretamente como root ou usando 'sudo' quando já logado como root."
  echo "      Exemplo: usuario_comum$ sudo $0"
  exit 1
fi

# ############################################################################################ #
# ### INTALAÇOES DE PACOTES                                                                ### #
# ############################################################################################ #

dnf install                             \
  gdm                                   \
  gnome-shell                           \
  gnome-terminal                        \
  gnome-shell-extension-just-perfection \
  gnome-shell-extension-blur-my-shell   \
  nautilus                              \
  nautilus-open-terminal                \
  adobe-source-code-pro-fonts           \
  distrobox                             \
  google-noto-sans-cjk-ttc-fonts        \
  google-noto-emoji-color-fonts         \
  -y --setopt=install_weak_deps=false

# ############################################################################################ #
# ### FUNÇÕES                                                                              ### #
# ############################################################################################ #

# executa como usuário que chamou o sudo
runas() {
  sudo -H -u "$SUDO_USER" -- "$@"
  return $?
}

# função para executar gsettings sem sessão iniciada para usuário 
gset() {
  local g_schema="$1"
  local g_key="$2"
  local g_value="$3"
  runas dbus-run-session gsettings set org.gnome.$g_schema "$g_key" "$g_value" 
}

# ############################################################################################ #
# ### ESTILIZAÇÃO DO GNOME                                                                 ### #
# ############################################################################################ #

# dark mode
gset desktop.interface      color-scheme                 "prefer-dark"
gset desktop.interface      gtk-theme                    "Adwaita-dark"
gset desktop.background     primary-color                "#2c3e50"
gset desktop.interface      accent-color                 "purple"

# shortcuts
gset desktop.wm.keybindings switch-applications          "[]"
gset desktop.wm.keybindings switch-applications-backward "[]"
gset desktop.wm.keybindings switch-windows               "['<Alt>Tab']"
gset desktop.wm.keybindings switch-windows-backward      "['<Shift><Alt>Tab']"

# exteção just-perfection: meu estilo da extensão
gset shell.extensions.just-perfection panel                          "false"
gset shell.extensions.just-perfection dash-icon-size                 "32"
gset shell.extensions.just-perfection dash-separator                 "false"
gset shell.extensions.just-perfection workspace-switcher-should-show "false"
gset shell.extensions.just-perfection search                         "false"
gset shell.extensions.just-perfection panel-in-overview              "true"

# IMORALIDADE: isso não mostra a mensagem de pedido de apoio
#              NÃO FAÇA ISSO EM PRODUÇÂO, DOE! para o projeto just-perfection 
gset shell.extensions.just-perfection support-notifier-showed-version "999"

# muda o formato de hora para 24hrs
gset desktop.interface clock-format "24h"

# habilita a extensões para o gnome
gset shell enabled-extensions "['just-perfection-desktop@just-perfection', 'blur-my-shell@aunetx']" 

# remove rodos os intens pinados na dash
gset shell favorite-apps "[]"

# ############################################################################################ #
# ### DISTROBOX                                                                            ### #
# ############################################################################################ #

runas bash -c "distrobox create        \
  --image fedora                       \
  --name day-by-day                    \
  --hostname day-by-day                \
  --home ~/.distrobox-homes/day-by-day \
  --nvidia                             \
  --yes"

runas bash -c "distrobox create       \
  --image fedora                      \
  --name sandbox                      \
  --hostname sandbox                  \
  --home ~/.distrobox-homes/sandbox   \
  --no-entry                          \
  --nvidia                            \
  --yes"

# ############################################################################################ #
# ### HABILITAR RPM FUSION                                                                 ### #
# ############################################################################################ #

sudo dnf install                                                                                      \ 
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm       \ 
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# ############################################################################################ #
# ### INSTALAR DRIVER DA NVIDIA SE NECESSÁRIO                                              ### #
# ############################################################################################ #

if lspci | grep -iq 'nvidia'; then
  dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings
fi

# ############################################################################################ #
# ### UPDATE & UPGRADE                                                                     ### #
# ############################################################################################ #

dnf upgrade -y
dnf update -y

# ############################################################################################ #
# ### DEFINIR SESSÃO COMO GRÁFICA POR PADRÃO E INICIAR INICIAR GDM                         ### #
# ############################################################################################ #

systemctl set-default graphical.target
systemctl start gdm
