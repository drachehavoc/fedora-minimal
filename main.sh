#!/bin/bash

################################################################################
### VERIFICAÇÕE & FUNÇÕES                                                    ###
################################################################################

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

################################################################################
### GNOME                                                                    ###
################################################################################

# install
dnf install -y --setopt=install_weak_deps=false \
  gdm \
  gnome-shell \
  gnome-terminal \
  nautilus \
  nautilus-open-terminal \ 
  adobe-source-code-pro-fonts \
  ;

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
fi

# define sessões graficas como padrão
systemctl set-default graphical.target

############################################################################################
### PLUGINS E CUTOMIZAÇÕES EXTRAS                                            ###
############################################################################################

if [ "$APPLY_GSETTINGS_FLAG" = true ]; then
  # instala as extenções
  dnf install -y --setopt=install_weak_deps=false \
      gnome-shell-extension-just-perfection \
      ;
  # habilita as extenções
  run_gsettings_for_user set org.gnome.shell enabled-extensions "['just-perfection-desktop@just-perfection']"
  # meu estilo 😉
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection panel false
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection dash false
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection search false
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection panel-in-overview true
  # remova isso, não seja panaca apoio o projeto / isso não mostra a mensagem de pedido de apoio
  run_gsettings_for_user set org.gnome.shell.extensions.just-perfection support-notifier-showed-version 999
fi

############################################################################################
### CLEANUP                                                                  ###
############################################################################################

# remover todos os apps pinados na dash 
run_gsettings_for_user set org.gnome.shell favorite-apps "[]"

############################################################################################
### INICIAR SESSÂO GDM                                                       ###
############################################################################################

systemctl start gdm
