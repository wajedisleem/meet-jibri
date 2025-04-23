#!/bin/bash
set -e

echo ">>> Checking if you are root user..."
if [[ "$(whoami)" != "root" ]]; then
    echo "This script must be run as root."
    exit 1
fi

echo ">>> Checking snd-aloop module support..."
modprobe snd_aloop || true
if [[ -z "$(grep snd_aloop /proc/modules)" ]]; then
    echo "snd_aloop module is not loaded! Please ensure the kernel supports it."
    exit 1
fi

echo ">>> Updating system and installing base packages..."
apt update
apt install -y alsa-utils kmod unzip sudo ffmpeg x11vnc

echo ">>> Installing Google Chrome..."
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt update
apt install -y google-chrome-stable
apt-mark hold google-chrome-stable

echo ">>> Installing ChromeDriver..."
CHROME_VER=$(dpkg -s google-chrome-stable | grep ^Version | cut -d " " -f2 | cut -d "-" -f1)
CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/$CHROME_VER/linux64/chromedriver-linux64.zip"
wget -O /tmp/chromedriver.zip $CHROMEDRIVER_URL
unzip /tmp/chromedriver.zip -d /usr/local/bin/
chmod +x /usr/local/bin/chromedriver

echo ">>> Installing Jibri..."
apt install -y jibri
apt-mark hold jibri

echo ">>> Configuring user and permissions..."
usermod -aG adm,audio,video,plugdev jibri
mkdir -p /usr/local/recordings
chown -R jibri:jibri /usr/local/recordings

echo ">>> Enabling and starting Jibri service..."
systemctl daemon-reexec
systemctl enable jibri
systemctl start jibri

echo "✅ Jibri installation and configuration completed successfully!"
