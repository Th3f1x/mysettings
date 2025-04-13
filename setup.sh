#!/bin/bash
chmod +x "$0"

# steps for finish
TOTAL_PASSOS=6
PROGRESSO=0

sudo -u "$SUDO_USER" pulseaudio --start
sudo -u "$SUDO_USER" pactl -- set-sink-mute @DEFAULT_SINK@ 0
sudo -u "$SUDO_USER" pactl -- set-sink-volume @DEFAULT_SINK@ 100%

# progress bar
atualizar_progresso() {
    PROGRESSO=$((PROGRESSO + 1))
    PERCENTUAL=$((PROGRESSO * 100 / TOTAL_PASSOS))
    echo -ne "Progresso: [$PROGRESSO/$TOTAL_PASSOS] $PERCENTUAL% \r"
    echo "
    "
    sleep 1
}

# update
echo "Atualizando pacotes..."
sudo apt-get update && sudo apt-get upgrade -y
atualizar_progresso

# Essentials
echo "Instalando pacotes essenciais..."
sudo apt install -y git curl zsh wget build-essential netdiscover macchanger wifite openssh-server pulseaudio
sudo -u "$SUDO_USER" systemctl start ssh
sudo -u "$SUDO_USER" systemctl enable ssh

atualizar_progresso

# GNOME Dash-to-Dock
echo -e "\e[33mgsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM\e[0m"
echo -e "\e[33mgsettings set org.gnome.shell.extensions.dash-to-dock extend-height false\e[0m"
echo -e "\e[33mgsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode FIXED\e[0m"
echo -e "\e[33mgsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36\e[0m"
echo -e "\e[33mgsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0\e[0m"
echo "
"
echo -e "\e[31mDigite os comandos acima em um terminal separado, após  isso  pressione *ENTER* para continuar a instalação:\e[0m"
read
atualizar_progresso

# ZSH theme
echo "
"
echo "Aplicando tema Zsh..."
sudo -u "$SUDO_USER" git clone https://github.com/egorlem/ultima.zsh-theme /home/$SUDO_USER/ultima-shell &>/dev/null
echo 'source ~/ultima-shell/ultima.zsh-theme' | sudo -u "$SUDO_USER" tee -a /home/$SUDO_USER/.zshrc &>/dev/null
sudo chsh -s $(which zsh) "$SUDO_USER"
atualizar_progresso

# wallpaper change
echo "Alterando wallpaper..."
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $SUDO_USER)/bus"
WALLPAPER_PATH="/home/$SUDO_USER/mysettings/wallpaper.jpg"
if [ -f "$WALLPAPER_PATH" ]; then
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
        gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH" &>/dev/null
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" &>/dev/null

else
    echo "Erro: Arquivo de wallpaper não encontrado."
    echo "Ignorando e continuando..."
    sleep "5"

atualizar_progresso

# Play a sound in every restart o init system 
USER_HOME="/home/$(logname)"
USER_ID=$(id -u "$SUDO_USER")
USER_ENV="XDG_RUNTIME_DIR=/run/user/$USER_ID DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus"

sudo -u "$SUDO_USER" mkdir -p "$USER_HOME/.config/autostart"

echo "[Desktop Entry]
Type=Application
Exec=mpv --no-video --volume=100 $USER_HOME/mysettings/a.mp3
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=StartupAudio
Comment=Toca um áudio ao iniciar a sessão do GNOME" | sudo tee "$USER_HOME/.config/autostart/play_audio.desktop" > /dev/null

sudo chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.config/autostart/play_audio.desktop"
sudo chmod 644 "$USER_HOME/.config/autostart/play_audio.desktop"

sudo -u "$SUDO_USER" mkdir -p "$USER_HOME/.config/systemd/user"

# systemd service
echo "[Unit]
Description=Reproduz um áudio no boot e na reinicialização da sessão
After=default.target

[Service]
ExecStart=/usr/bin/mpv --no-video --volume=100 $USER_HOME/mysettings/a.mp3
Restart=on-failure
Environment=DISPLAY=:0
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u "$SUDO_USER")

[Install]
WantedBy=default.target" | sudo tee "$USER_HOME/.config/systemd/user/play_audio.service" > /dev/null

sudo chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.config/systemd/user/play_audio.service"
sudo chmod 644 "$USER_HOME/.config/systemd/user/play_audio.service"
sudo -u "$SUDO_USER" env $USER_ENV systemctl --user daemon-reload
sudo -u "$SUDO_USER" env $USER_ENV systemctl --user enable play_audio.service
sudo -u "$SUDO_USER" env $USER_ENV systemctl --user start play_audio.service

echo "Reiniciando..."

sleep "5"

# restart gnome
sudo -u "$SUDO_USER" killall -SIGUSR1 gnome-shell
fi
