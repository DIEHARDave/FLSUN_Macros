#!/bin/bash
# FLSUN_Macros installer for the FLSun T1 Pro.
# Run as the pi user from the cloned repo: ~/FLSUN_Macros/install.sh
# Safe to re-run, e.g. after a FLSun firmware update.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/printer_data/config"
MOONRAKER_CONF="${CONFIG_DIR}/moonraker.conf"
PRINTER_CFG="${CONFIG_DIR}/printer.cfg"
MOONRAKER_URL="http://127.0.0.1:7125"
SAVE_CONFIG_MARKER='#\*# <-* SAVE_CONFIG -*>'

msg() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "run as the pi user, not root (sudo is used where needed)"
[ -f "$MOONRAKER_CONF" ] || die "$MOONRAKER_CONF not found"
[ -f "$PRINTER_CFG" ] || die "$PRINTER_CFG not found"

# Restarting Klipper mid-print would kill the print.
state=$(curl -s -m 5 "${MOONRAKER_URL}/printer/objects/query?print_stats=state" \
    | sed -n 's/.*"state": *"\([a-z]*\)".*/\1/p')
case "$state" in
    printing|paused) die "a print is $state; run this again when the printer is idle" ;;
esac

# Clock, certificates and git https support, which updates need; see
# prepare.sh.
"${REPO_DIR}/prepare.sh"

msg "Installing the boot service that sets the clock"
sudo install -m 755 "${REPO_DIR}/system/flsun-timesync" /usr/local/bin/flsun-timesync
sudo install -m 644 "${REPO_DIR}/system/flsun-timesync.service" /etc/systemd/system/flsun-timesync.service
sudo systemctl daemon-reload
sudo systemctl enable flsun-timesync.service > /dev/null 2>&1

msg "Linking the Klipper macros"
# Every .cfg in klipper/ is loaded, so new macro files need no new include.
ln -sfn "${REPO_DIR}/klipper" "${CONFIG_DIR}/flsun_macros"
if ! grep -q '^\[include flsun_macros/\*\.cfg\]' "$PRINTER_CFG"; then
    cp "$PRINTER_CFG" "${PRINTER_CFG}.flsun_macros.bak"
    # Above SAVE_CONFIG's block, which must stay last: Klipper ignores the
    # saved calibration if anything follows it.
    if grep -q "^${SAVE_CONFIG_MARKER}" "$PRINTER_CFG"; then
        sed -i "/^${SAVE_CONFIG_MARKER}/i [include flsun_macros/*.cfg]\n" "$PRINTER_CFG"
    else
        printf '\n[include flsun_macros/*.cfg]\n' >> "$PRINTER_CFG"
    fi
fi

msg "Adding the update manager entry"
ln -sfn "${REPO_DIR}/moonraker/flsun_macros.conf" "${CONFIG_DIR}/flsun_macros.conf"
if ! grep -q '^\[include flsun_macros\.conf\]' "$MOONRAKER_CONF"; then
    cp "$MOONRAKER_CONF" "${MOONRAKER_CONF}.flsun_macros.bak"
    printf '\n[include flsun_macros.conf]\n' >> "$MOONRAKER_CONF"
fi

msg "Restarting Moonraker and Klipper"
sudo systemctl restart moonraker
sudo systemctl restart klipper

msg "Done. See https://github.com/DIEHARDave/FLSUN_Macros for the slicer lines."
