#!/usr/bin/env bash
# shellcheck disable=SC2034

SYSTEM_NOTIFICATIONS_GSETTINGS=(
    "org.cinnamon.desktop.notifications|bottom-notifications|true"
    "org.cinnamon.desktop.notifications|display-notifications|true"
    "org.cinnamon.desktop.notifications|fade-on-mouseover|true"
    "org.cinnamon.desktop.notifications|fade-opacity|40"
    "org.cinnamon.desktop.notifications|fullscreen-notifications|false"
    "org.cinnamon.desktop.notifications|notification-duration|3"
    "org.cinnamon.desktop.notifications|notification-fixed-screen|1"
    "org.cinnamon.desktop.notifications|notification-screen-display|'primary-screen'"
    "org.cinnamon.desktop.notifications|remove-old|false"
    "org.cinnamon.desktop.notifications|timeout|1800"
    "org.cinnamon.settings-daemon.plugins.power|power-notifications-for-keyboard|true"
    "org.cinnamon.settings-daemon.plugins.power|power-notifications-for-mouse|true"
    "org.cinnamon.settings-daemon.plugins.power|power-notifications-for-other-devices|true"
)
