# FLSUN_Macros

Klipper macros for the **FLSun T1 Pro** that its stock firmware is missing, installed as a plugin and kept up to date through Mainsail's and Fluidd's update manager.

| Macro file | What it adds |
| :--- | :--- |
| `pause_at_layer.cfg` | Pause (or run `M600` or any macro) at a chosen layer |

## Pause at layer

The same commands that Mainsail's standard macros provide on Zmod (Flashforge AD5X, AD5M, Creator 5) and on the Snapmaker U1, so they work the same way on all of them:

| Command | What it does |
| :--- | :--- |
| `SET_PAUSE_AT_LAYER LAYER=12` | Pause when layer 12 starts |
| `SET_PAUSE_AT_LAYER LAYER=12 MACRO=M600` | Run `M600` (filament change) instead of `PAUSE` |
| `SET_PAUSE_AT_LAYER ENABLE=0` | Clear the layer pause |
| `SET_PAUSE_NEXT_LAYER` | Pause when the next layer starts |
| `SET_PAUSE_NEXT_LAYER ENABLE=0` | Clear the next-layer pause |

Each pause fires once, then clears itself. `RESUME` continues the print as usual.

`SET_PAUSE_AT_LAYER` without `LAYER=` turns the pause off, the same as on Zmod and the U1. A pause that is never reached, for example because you cancelled the print, stays set for the next print until you clear it.

### Slicer setup (required)

The T1 Pro's firmware doesn't know which layer it's printing, so the slicer has to tell it. In OrcaSlicer, open the printer profile, then **Machine G-code**:

- At the end of **Machine start G-code**, add:

  ```
  SET_PRINT_STATS_INFO TOTAL_LAYER=[total_layer_count]
  ```

- In **Layer change G-code**, add:

  ```
  SET_PRINT_STATS_INFO CURRENT_LAYER={layer_num + 1}
  ```

Re-slice your files afterwards; files sliced before the change never pause. Layers are numbered from 1, as in Orca's preview.

Without this plugin, the T1 Pro's Klipper doesn't have `SET_PRINT_STATS_INFO`, so these lines only log "Unknown command" and nothing pauses.

## Install

If you use [FLSUN_Updater](https://github.com/DIEHARDave/FLSUN_Updater), set `flsun_macros: yes` in `flsun_plugins.cfg`, or run `ENABLE_PLUGIN NAME=flsun_macros` in the console.

To install by hand, SSH into the printer as `pi` (the default password is `1`).

1. Prepare the system. FLSun's system image can't reach GitHub as shipped: the clock starts about a year and a half in the past, the certificate links are missing, and git's https support was removed. These commands fix all three (skip them if another FLSUN_ plugin is already installed, since each of them makes the same fixes):

   ```sh
   sudo ntpdate -u -b time.google.com
   curl -fsSL --cacert /etc/ssl/certs/ca-certificates.crt https://raw.githubusercontent.com/DIEHARDave/FLSUN_Macros/main/prepare.sh | bash
   ```

   Don't use `timedatectl set-ntp true`: on this image it stops the time service rather than starting it.

2. Download and install the plugin while the printer is idle:

   ```sh
   cd ~
   git clone https://github.com/DIEHARDave/FLSUN_Macros.git
   ~/FLSUN_Macros/install.sh
   ```

The installer restarts Moonraker and Klipper. It is safe to run again, for example after a FLSun firmware update that resets your config.

## Files

| Path | What it is |
| :--- | :--- |
| `~/printer_data/config/flsun_macros/` | Link to the macro files; `printer.cfg` includes every `.cfg` in it. |
| `~/printer_data/config/flsun_macros.conf` | Link to the update manager entry; included from `moonraker.conf`. |

Updates come through Mainsail's and Fluidd's update manager (`flsun_macros`). Don't edit the macro files: an update would refuse to overwrite them. Copy a macro into your own config instead.

## Uninstall

```sh
~/FLSUN_Macros/uninstall.sh
rm -rf ~/FLSUN_Macros
```

The uninstaller keeps the clock-sync service from step 1.

## Credits

The pause-at-layer macros follow [mainsail-config](https://github.com/mainsail-crew/mainsail-config)'s `SET_PAUSE_AT_LAYER` and `SET_PAUSE_NEXT_LAYER`. Licensed under the GNU GPLv3, the same as mainsail-config.
