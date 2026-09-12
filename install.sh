#!/bin/sh

set -eu

SERVICE_NAME="fix-hda-audio.service"
SERVICE_SOURCE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/$SERVICE_NAME"
FIX_SOURCE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/fix-hda-audio"

SERVICE_DEST="/etc/systemd/system/$SERVICE_NAME"
FIX_DEST="/usr/local/sbin/fix-hda-audio"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: run this installer with sudo."
    exit 1
fi

if [ ! -f "$SERVICE_SOURCE" ] || [ ! -f "$FIX_SOURCE" ]; then
    echo "Error: required project files were not found."
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "Error: systemd was not found."
    echo "This installer requires systemd."
    exit 1
fi

if ! command -v lspci >/dev/null 2>&1; then
    echo "Error: lspci was not found."
    echo "Install the pciutils package and run the installer again."
    exit 1
fi

if ! lspci -Dn | grep -Eq '(^| )8086:3b56( |$)' ; then
    echo "Error: Intel HDA controller 8086:3b56 was not detected."
    echo "The installer will not install the workaround on this system."
    exit 1
fi

install -m 0644 "$SERVICE_SOURCE" "$SERVICE_DEST"
install -m 0755 "$FIX_SOURCE" "$FIX_DEST"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

echo
echo "Intel 5-Series HDA Audio Fix installed successfully."
echo
echo "The workaround will run automatically during boot."
echo
echo "To test it now:"
echo "  sudo systemctl start $SERVICE_NAME"
echo
echo "To check the service:"
echo "  systemctl status $SERVICE_NAME"
echo
echo "Reboot to test the fix from a clean boot:"
echo "  sudo reboot"