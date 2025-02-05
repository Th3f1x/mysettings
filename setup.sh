#!/bin/bash

# Número total de passos do script
TOTAL_PASSOS=6
PROGRESSO=0

sudo -u "$SUDO_USER" pulseaudio --start
sudo -u "$SUDO_USER" pactl -- set-sink-mute @DEFAULT_SINK@ 0
sudo -u "$SUDO_USER" pactl -- set-sink-volume @DEFAULT_SINK@ 100%

# Função para atualizar a barra de progresso
atualizar_progresso() {
    PROGRESSO=$((PROGRESSO + 1))
    PERCENTUAL=$((PROGRESSO * 100 / TOTAL_PASSOS))
    echo -ne "Progresso: [$PROGRESSO/$TOTAL_PASSOS] $PERCENTUAL% \r"
    sleep 0.5
}

# Atualiza pacotes
echo "Atualizando pacotes..."
sudo apt-get update &>/dev/null && sudo apt-get upgrade -y &>/dev/null
atualizar_progresso

# Instala pacotes essenciais
echo "Instalando pacotes essenciais..."
sudo apt install -y git curl zsh wget build-essential netdiscover macchanger wifite &>/dev/null
atualizar_progresso

# Configuração do GNOME Dash-to-Dock
echo "Configurando o GNOME Dash-to-Dock..."
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $SUDO_USER)/bus"
sudo -u "$SUDO_USER" gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM &>/dev/null
sudo -u "$SUDO_USER" gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false &>/dev/null
sudo -u "$SUDO_USER" gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode FIXED &>/dev/null
sudo -u "$SUDO_USER" gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36 &>/dev/null
sudo -u "$SUDO_USER" gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0 &>/dev/null
atualizar_progresso

# Configuração do tema Zsh
echo "Aplicando tema Zsh..."
sudo -u "$SUDO_USER" git clone https://github.com/egorlem/ultima.zsh-theme /home/$SUDO_USER/ultima-shell &>/dev/null
echo 'source ~/ultima-shell/ultima.zsh-theme' | sudo -u "$SUDO_USER" tee -a /home/$SUDO_USER/.zshrc &>/dev/null
sudo chsh -s $(which zsh) "$SUDO_USER"
atualizar_progresso

# Define papel de parede
echo "Alterando wallpaper..."
WALLPAPER_PATH="/home/$SUDO_USER/mysettings/wallpaper.jpg"
if [ -f "$WALLPAPER_PATH" ]; then
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
        gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH" &>/dev/null
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" &>/dev/null
else
    echo "Erro: Arquivo de wallpaper não encontrado."
    exit 1
fi
atualizar_progresso

sudo -u "$SUDO_USER" bash -c 'export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"; mpv --no-video --volume=100 ~/mysettings/a.mp3 &'

echo -e "\nConfiguração finalizada"