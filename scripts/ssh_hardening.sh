#!/usr/bin/env bash
set -e

echo "[*] SSH hardening starting..."

# -------------------------
# Sanity checks
# -------------------------
if [[ "$EUID" -ne 0 ]]; then
  echo "[!] Run this script with sudo:"
  echo "    sudo ./ssh_hardening.sh"
  exit 1
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.bak.$(date +%F_%T)"

# -------------------------
# Backup
# -------------------------
echo "[*] Backing up sshd_config to $BACKUP"
cp "$SSHD_CONFIG" "$BACKUP"

# -------------------------
# Apply settings (HTB-style)
# -------------------------
echo "[*] Applying SSH hardening settings..."

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' "$SSHD_CONFIG"
sed -i 's/^#\?UsePAM.*/UsePAM yes/' "$SSHD_CONFIG"
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSHD_CONFIG"
sed -i 's/^#\?Protocol.*/Protocol 2/' "$SSHD_CONFIG"
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSHD_CONFIG"
sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 600/' "$SSHD_CONFIG"
sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 0/' "$SSHD_CONFIG"
sed -i 's/^#\?LogLevel.*/LogLevel VERBOSE/' "$SSHD_CONFIG"
sed -i 's/^#\?DebianBanner.*/DebianBanner no/' "$SSHD_CONFIG"

# -------------------------
# Append required lines if missing
# -------------------------
grep -q "^AuthenticationMethods" "$SSHD_CONFIG" || \
echo "AuthenticationMethods publickey,keyboard-interactive" >> "$SSHD_CONFIG"

# -------------------------
# Test config BEFORE restart
# -------------------------
echo "[*] Testing sshd configuration..."
sshd -t

# -------------------------
# Restart SSH
# -------------------------
echo "[*] Restarting SSH service..."
systemctl restart ssh

echo "[✓] SSH hardening applied successfully."
echo "    Keep your current SSH session open and test a new login NOW."

