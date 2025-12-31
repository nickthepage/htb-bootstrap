#!/usr/bin/env bash
set -euo pipefail

### VARIABLES ###
REPO_URL="git@github.com:nickthepage/htb-bootstrap.git"
INSTALL_DIR="$HOME/htb-bootstrap"
USER_NAME="$(whoami)"

### ENSURE NON-INTERACTIVE ###
export DEBIAN_FRONTEND=noninteractive

echo "[+] Updating system"
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y git curl vim tmux zsh qrencode fail2ban \
                    libpam-google-authenticator python3-pip

### CLONE REPO ###
if [ ! -d "$INSTALL_DIR" ]; then
    echo "[+] Cloning bootstrap repository"
    git clone "$REPO_URL" "$INSTALL_DIR"
else
    echo "[+] Repo already exists, pulling updates"
    git -C "$INSTALL_DIR" pull
fi

cd "$INSTALL_DIR"

### INSTALL APT PACKAGES ###
if [ -f apt/packages.txt ]; then
    echo "[+] Installing apt packages"
    sudo apt install -y $(grep -vE '^#|^$' apt/packages.txt)
fi

### SSH HARDENING ###
echo "[+] Hardening SSH"
sudo cp ssh/sshd_config.hardened /etc/ssh/sshd_config
sudo systemctl restart ssh

### FAIL2BAN ###
echo "[+] Enabling Fail2Ban"
sudo systemctl enable --now fail2ban

### GOOGLE AUTHENTICATOR (NON-INTERACTIVE) ###
if [ ! -f "$HOME/.google_authenticator" ]; then
    echo "[+] Setting up Google Authenticator"
    google-authenticator -t -d -f -r 3 -R 30 -W
fi

### ZSH + OH-MY-ZSH ###
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[+] Installing Oh My Zsh"
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ln -sf "$INSTALL_DIR/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$INSTALL_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"

### SET DEFAULT SHELL ###
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s "$(which zsh)" "$USER_NAME"
fi

### TMUX + TPM ###
mkdir -p "$HOME/.tmux/plugins"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "[+] Installing TPM"
    git clone https://github.com/tmux-plugins/tpm \
        "$HOME/.tmux/plugins/tpm"
fi

ln -sf "$INSTALL_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

### INSTALL TMUX PLUGINS (NO PREFIX) ###
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

echo
echo "[✔] Bootstrap complete"
echo "[!] Reboot recommended"

