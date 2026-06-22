#!/usr/bin/env bash
# shellcheck disable=SC2034

SYSTEM_KEYBOARD_GSETTINGS=(
    "org.gnome.desktop.input-sources|sources|[('xkb', 'be')]"
    "org.gnome.desktop.input-sources|xkb-model|'pc105+inet'"
    "org.gnome.desktop.input-sources|xkb-options|@as []"
    "org.gnome.desktop.input-sources|show-all-sources|false"
    "org.gnome.desktop.input-sources|per-window|false"
    "org.cinnamon.desktop.peripherals.keyboard|delay|uint32 500"
    "org.cinnamon.desktop.peripherals.keyboard|repeat|true"
    "org.cinnamon.desktop.peripherals.keyboard|repeat-interval|uint32 30"
    "org.cinnamon.desktop.peripherals.keyboard|numlock-state|true"
    "org.cinnamon.desktop.peripherals.keyboard|remember-numlock-state|true"
)
