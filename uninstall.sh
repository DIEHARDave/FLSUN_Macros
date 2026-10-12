#!/bin/bash
# Removes FLSUN_Macros. The slicer lines in your Orca profile are harmless
# without it (Klipper only logs "Unknown command"), but you can delete them.

set -e

CONFIG_DIR="${HOME}/printer_data/config"
MOONRAKER_CONF="${CONFIG_DIR}/moonraker.conf"
PRINTER_CFG="${CONFIG_DIR}/printer.cfg"

msg() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

[ "$(id -u)" -ne 0 ] || { echo "run as the pi user, not root" >&2; exit 1; }

msg "Removing the Klipper macros"
sed -i '/^\[include flsun_macros\/\*\.cfg\]/d' "$PRINTER_CFG"
[ -L "${CONFIG_DIR}/flsun_macros" ] && rm -f "${CONFIG_DIR}/flsun_macros"

msg "Removing the update manager entry"
sed -i '/^\[include flsun_macros\.conf\]/d' "$MOONRAKER_CONF"
[ -L "${CONFIG_DIR}/flsun_macros.conf" ] && rm -f "${CONFIG_DIR}/flsun_macros.conf"

# The flsun-timesync boot service from prepare.sh is left in place on
# purpose: a correct clock helps everything else on the printer too.

msg "Restarting Moonraker and Klipper"
sudo systemctl restart moonraker
sudo systemctl restart klipper

msg "Done. Delete ~/FLSUN_Macros to finish."
