#!/bin/sh

set -eu

SERVICE_NAME="fix-hda-audio.service"
SERVICE_DEST="/etc/systemd/system/$SERVICE_NAME"
FIX_DEST="/usr/local/sbin/fix-hda-audio"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: run this uninstaller with sudo."
    exit 1
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
fi

rm -f "$SERVICE_DEST"
rm -f "$FIX_DEST"

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
fi

echo "Intel 5-Series HDA Audio Fix removed."
echo "Reboot your system to return to normal boot behavior."