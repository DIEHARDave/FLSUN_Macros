# FLSUN_Macros

Klipper macros for the **FLSun T1 Pro** that its stock firmware is missing, installed as a plugin and kept up to date through Mainsail's and Fluidd's update manager. They work with FLSun's Klipper and with upstream Klipper ([FLSUN_klipper](https://github.com/DIEHARDave/FLSUN_klipper)).

| Macro file | What it adds |
| :--- | :--- |
| `pause_at_layer.cfg` | Pause (or run `M600` or any macro) at a chosen layer |
| `print_start.cfg` | `PRINT_START` and `PRINT_END`: heat soak and Z offset per material, a bed mesh for the bed temperature, a prime line |
| `bed_mesh.cfg` | Bed meshes per bed temperature (`MESH_IF_NEEDED`, `MESH_TEMP_SWEEP`), and `BED_LEVEL_1`/`BED_LEVEL_2` that keep your temperatures |
| `filament.cfg` | `LOAD_FILAMENT` and `UNLOAD_FILAMENT` |
| `tuning.cfg` | `PID_EXTRUDER` and `PID_BED` |
| `light.cfg` | `LED_ON` and `LED_OFF` for the chamber light |
| `base.cfg` | `[respond]` and `[exclude_object]`, which the macros and Orca's object lines need |

`LOAD_FILAMENT`, `UNLOAD_FILAMENT`, `BED_LEVEL_1` and `BED_LEVEL_2` replace FLSun's. The other names are new, so your own macros keep working; a macro of yours with the same name as one here is replaced by this one.

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

`SET_PAUSE_AT_LAYER` without `LAYER=` turns the pause off, the same as on Zmod and the U1. The settings are saved (in `savedVariables1.cfg`), so a pause survives a restart or a power loss. A pause that is never reached, for example because you cancelled the print, stays set for the next print until you clear it.

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

## Print start and end

Orca's **Machine start G-code**:

```
PRINT_START BED={bed_temperature_initial_layer_single} EXTRUDER={nozzle_temperature_initial_layer[0]} MATERIAL={filament_type[0]}
SET_PRINT_STATS_INFO TOTAL_LAYER=[total_layer_count]
```

**Machine end G-code**:

```
PRINT_END
END_PRINT
```

`PRINT_START` homes and heats the bed, waits for the bed to soak (1 minute for PLA, 2 for PETG, 5 for ASA and ABS, 3 for others), loads the bed mesh for that bed temperature (making it first if there isn't one, see below), heats the nozzle and draws a prime line. It also sets the Z offset for the material (0 unless you set one). `PRINT_END` retracts 30 mm, turns the heaters and the part fan off and homes; FLSun's `END_PRINT` then cools the print with the part fan for 100 seconds.

The soak times and Z offsets are defaults. To change one, use `SET_START_PRINT_VAR`; it's saved, so it survives restarts:

| Command | What it does |
| :--- | :--- |
| `SHOW_START_PRINT_VARS` | List the settings, and which ones you've changed |
| `SET_START_PRINT_VAR NAME=offset_petg VALUE=0.03` | Z offset for PETG, in mm (`offset_pla`, `offset_petg`, `offset_asa`, `offset_abs`, `offset_default`) |
| `SET_START_PRINT_VAR NAME=wait_abs VALUE=8` | Bed soak for ABS, in minutes (`wait_pla`, `wait_petg`, `wait_asa`, `wait_abs`, `wait_default`) |
| `SET_START_PRINT_VAR NAME=offset_probe VALUE=1` | Don't set a material Z offset; rely on the probe |
| `SET_START_PRINT_VAR NAME=wait_abs VALUE=DEFAULT` | Back to the default |

## Bed mesh per temperature

A bed shifts as it heats, so a mesh made at 60 °C doesn't fit a 100 °C bed. `PRINT_START` loads a mesh named after the bed temperature, such as `60.0c`, and probes one (after a 1-minute soak) if it doesn't exist yet. A mesh made that way lasts until Klipper restarts; run `SAVE_CONFIG` after the print to keep it. `MESH_TEMP_SWEEP` makes them all at once, from 55 to 110 °C in 5 °C steps, and saves them; it takes a while.

`BED_LEVEL_1` and `BED_LEVEL_2` replace FLSun's. Set the bed and nozzle to your usual printing temperatures first. `BED_LEVEL_1` remembers them, then runs the delta calibration at 140 °C (nozzle) and 60 °C (bed), like FLSun's. `BED_LEVEL_2` heats back to the temperatures you set and makes the mesh there. Neither saves on its own: run `SAVE_CONFIG` afterwards (it restarts Klipper).

## Filament, PID and light

- `LOAD_FILAMENT` heats the nozzle to 240 °C if it's colder than 235 °C, then feeds 230 mm in. For other materials, heat the nozzle yourself first. `UNLOAD_FILAMENT` pulls 100 mm back out; heat the nozzle first.
- `PID_EXTRUDER` (270 °C) and `PID_BED` (100 °C) tune the heaters and save the result.
- `LED_ON` and `LED_OFF` switch the chamber light.

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

`BED_LEVEL_1` and `BED_LEVEL_2` are from [u/tuxlinux](https://www.reddit.com/user/tuxlinux/), and `SHORT_PRIME_LINE` from [u/TheDepep1](https://www.reddit.com/user/TheDepep1/), shared on Reddit for the T1 Pro. The pause-at-layer macros follow [mainsail-config](https://github.com/mainsail-crew/mainsail-config)'s `SET_PAUSE_AT_LAYER` and `SET_PAUSE_NEXT_LAYER`. Licensed under the GNU GPLv3, the same as mainsail-config.
