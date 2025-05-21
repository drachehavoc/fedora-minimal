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

# install cleanup
dnf remove -y \
  gnome-tour
  
