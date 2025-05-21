#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root (ex: usando sudo)."
  exit 1
fi

# Determina o usuário alvo
APPLY_GSETTINGS_FLAG=true # Assume que vamos aplicar por padrão
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  TARGET_USER="$SUDO_USER"
  echo "INFO: Configurações GSettings serão aplicadas para o usuário: $TARGET_USER"
else
  echo "AVISO: Não foi possível determinar um usuário alvo não-root automaticamente via SUDO_USER."
  echo "       (Variável SUDO_USER: '${SUDO_USER:-nao_definida}')"
  echo "       As configurações GSettings específicas do usuário não serão aplicadas."
  APPLY_GSETTINGS_FLAG=false
fi


################################################################################
### GNOME                                                                    ###
################################################################################

echo ">>> Instalando pacotes GNOME..."
# install
dnf install -y \
  gdm \
  gnome-shell \
  gnome-terminal \
  nautilus \
  nautilus-open-terminal \
  adobe-source-code-pro-fonts

echo ">>> Removendo pacotes..."
# cleanup
dnf remove -y \
  gnome-tour

# gsettings
if [ "$APPLY_GSETTINGS_FLAG" = true ]; then
  if id "$TARGET_USER" &>/dev/null; then
    echo ">>> Aplicando configurações GSettings para o usuário $TARGET_USER..."

    run_gsettings_for_user() {
      local g_subcommand="$1"
      local g_schema="$2"
      local g_key="$3"
      local g_value="$4"

      echo "  Executando para $TARGET_USER: gsettings $g_subcommand $g_schema $g_key (valor omitido para brevidade no log)"
      # Alternativamente, para ver o valor, mas com cuidado com caracteres especiais no echo:
      # printf "  Executando para %s: gsettings %s %s %s '%s'\n" "$TARGET_USER" "$g_subcommand" "$g_schema" "$g_key" "$g_value"

      if ! sudo -H -u "$TARGET_USER" dbus-run-session gsettings "$g_subcommand" "$g_schema" "$g_key" "$g_value"; then
        echo "  AVISO: Falha ao executar gsettings $g_subcommand $g_schema $g_key para o usuário $TARGET_USER"
      fi
    }

    # dark mode
    run_gsettings_for_user "set" "org.gnome.desktop.interface" "color-scheme" "prefer-dark"
    run_gsettings_for_user "set" "org.gnome.desktop.interface" "gtk-theme" "Adwaita-dark"
    run_gsettings_for_user "set" "org.gnome.desktop.background" "primary-color" "#2c3e50"
    # Para accent-color, 'purple' pode não ser um valor padrão.
    # Considere usar um valor hexadecimal como '#800080' ou verificar os valores válidos.
    run_gsettings_for_user "set" "org.gnome.desktop.interface" "accent-color" "purple" # Exemplo: '#800080'

    # shortcuts
    run_gsettings_for_user "set" "org.gnome.desktop.wm.keybindings" "switch-applications" "[]"
    run_gsettings_for_user "set" "org.gnome.desktop.wm.keybindings" "switch-applications-backward" "[]"
    run_gsettings_for_user "set" "org.gnome.desktop.wm.keybindings" "switch-windows" "['<Alt>Tab']"
    run_gsettings_for_user "set" "org.gnome.desktop.wm.keybindings" "switch-windows-backward" "['<Shift><Alt>Tab']"

  else
    echo "AVISO: Usuário alvo '$TARGET_USER' (determinado para GSettings) não encontrado no sistema. Pulando configurações GSettings."
  fi
else
  # A mensagem de aviso já foi dada na seção de detecção de usuário.
  echo "INFO: Aplicação de GSettings pulada."
fi

echo ">>> Definindo target gráfico como padrão..."
# set graphical as default
systemctl set-default graphical.target

echo ">>> Configuração do GNOME concluída."
