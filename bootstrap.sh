#!/usr/bin/env bash
set -e

echo "[*] HTB Bootstrap starting..."

# -------------------------
# Variables
# -------------------------
USER_HOME="$HOME"
REPO_DIR="$HOME/htb-bootstrap"

# -------------------------
# Sanity checks
# -------------------------
if [[ "$EUID" -eq 0 ]]; then
  echo "[!] Do NOT run this script as root."
  exit 1
fi

if [[ ! -d "$REPO_DIR" ]]; then
  echo "[!] Repo not found at $REPO_DIR"
  echo "    Clone it first:"
  echo "    git clone https://github.com/nickthepage/htb-bootstrap.git"
  exit 1
fi

# -------------------------
# System update
# -------------------------
echo "[*] Updating system..."
sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

# -------------------------
# Install base packages
# -------------------------
echo "[*] Installing base packages..."

BASE_PACKAGES=(
  git
  curl
  wget
  vim
  tmux
  zsh
  unzip
  htop
  net-tools
  build-essential
  ca-certificates
  gnupg
)
echo "[*] Installing HTB tools..."
xargs -a "$REPO_DIR/apt/packages.txt" sudo apt install -y


sudo apt install -y "${BASE_PACKAGES[@]}"

# -------------------------
# Install Oh My Zsh
# -------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "[*] Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "[*] Oh My Zsh already installed."
fi

# -------------------------
# Zsh plugins
# -------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "[*] Installing Zsh plugins..."

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# -------------------------
# Powerlevel10k
# -------------------------
if [[ ! -d "$HOME/powerlevel10k" ]]; then
  echo "[*] Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
fi

# -------------------------
# Apply dotfiles
# -------------------------
echo "[*] Applying dotfiles..."

if [[ -f "$REPO_DIR/zsh/.zshrc" ]]; then
  ln -sf "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
fi

if [[ -f "$REPO_DIR/tmux/.tmux.conf" ]]; then
  ln -sf "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

# -------------------------
# tmux plugin manager
# -------------------------
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo "[*] Installing tmux plugin manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# -------------------------
# Default shell
# -------------------------
if [[ "$SHELL" != */zsh ]]; then
  echo "[*] Changing default shell to zsh..."
  chsh -s "$(which zsh)"
fi

echo "[✓] Bootstrap complete."
echo "    Restart your terminal or run: exec zsh"

