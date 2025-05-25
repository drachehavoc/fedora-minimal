#!/bin/bash

############################################################################################
### VERIFICAÇÕE & FUNÇÕES                                                                ###
############################################################################################

# verificar se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root (ex: usando sudo)."
  exit 1
fi

# determina o usuário alvo
APPLY_GSETTINGS_FLAG=false # Assume que NÃO vamos aplicar por padrão
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  echo "INFO: Configurações GSettings serão aplicadas para o usuário: $TARGET_USER"
  TARGET_USER="$SUDO_USER"
  APPLY_GSETTINGS_FLAG=true
else
  echo "AVISO: Não foi encontrado um usuário para aplicação de Configurações GSettings."
  # APPLY_GSETTINGS_FLAG=false
fi

# função para usar gsettings sem sessão iniciada para usuário 
run_gsettings_for_user() {
  local g_subcommand="$1"
  local g_schema="$2"
  local g_key="$3"
  local g_value="$4"
  if ! sudo -H -u "$TARGET_USER" dbus-run-session gsettings "$g_subcommand" "$g_schema" "$g_key" "$g_value"; then
    echo "  AVISO: Falha ao executar gsettings $g_subcommand $g_schema $g_key para o usuário $TARGET_USER"
  fi
}

############################################################################################
### INTALAÇOES DE PACOTES                                                                ###
############################################################################################

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


############################################################################################
### GNOME                                                                                ###
############################################################################################

# define sessões gráficas como padrão
#systemctl set-default graphical.target

  
# gsettings
if [ "$APPLY_GSETTINGS_FLAG" = true ]; then
  # dark mode
  run_gsettings_for_user set org.gnome.desktop.interface color-scheme "prefer-dark"
  run_gsettings_for_user set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
  run_gsettings_for_user set org.gnome.desktop.background primary-color "#2c3e50"
  run_gsettings_for_user set org.gnome.desktop.interface accent-color "purple"
  # shortcuts
  run_gsettings_for_user set org.gnome.desktop.wm.keybindings switch-applications "[]"
  run_gsettings_for_user set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
  run_gsettings_for_user set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
  run_gsettings_for_user set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
  # muda o formato de hora para 24hrs
  run_gsettings_for_user set org.gnome.desktop.interface clock-format 24h    
  # habilita a extensões para o gnome
  run_gsettings_for_user set org.gnome.shell enabled-extensions "['just-perfection-desktop@just-perfection', 'blur-my-shell@aunetx']"
  # exteção just-perfection: meu estilo da extensão
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection panel false
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection dash-icon-size 32
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection dash-separator false
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection workspace-switcher-should-show false
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection search false
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection panel-in-overview true
  # isso não mostra a mensagem de pedido de apoio
  # NÃO FAÇA ISSO EM PRODUÇÂO, DOE! para o projeto just-perfection 
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection support-notifier-showed-version 999
fi

############################################################################################
### DISTROBOX                                                                            ###
############################################################################################

clear

read -p "Press key to continue.. " -n1 -s

distrobox create                      \
  --image fedora                      \
  --name day-by-day                   \
  --hostname day-by-day               \
  --home ~/Distrobox-Homes/day-by-day \
  --nvidia                            \
  --yes

read -p "Press key to continue.. " -n1 -s

distrobox create                      \
  --image fedora                      \
  --name sandbox                      \
  --hostname sandbox                  \
  --home ~/Distrobox-Homes/sandbox    \
  --no-entry                          \
  --nvidia                            \
  --yes

############################################################################################
### CLEANUP                                                                              ###
############################################################################################

# remove rodos os intens pinados na dash
if [ "$APPLY_GSETTINGS_FLAG" = true ]; then
  run_gsettings_for_user set org.gnome.shell favorite-apps "[]"
fi

############################################################################################
### INICIAR SESSÂO GDM                                                                   ###
############################################################################################

systemctl start gdm
