#!/usr/bin/env bash
# shellcheck disable=SC2034

SYSTEM_MISC_GSETTINGS_GROUPS=(
    "Set dark blue theme;org.cinnamon.desktop.interface|gtk-theme|'Mint-Y-Dark-Blue';org.cinnamon.desktop.interface|icon-theme|'Mint-Y-Blue';org.cinnamon.theme|name|'Mint-Y-Dark-Blue';org.x.apps.portal|color-scheme|'prefer-dark'"
    "Set text scaling factor;org.cinnamon.desktop.interface|text-scaling-factor|1.8000000000000005;org.gnome.desktop.interface|text-scaling-factor|1.8000000000000005"
    "Set date and time preferences;org.cinnamon.desktop.interface|first-day-of-week|1;org.cinnamon.desktop.interface|clock-use-24h|true"
    "Disable recent file history;org.cinnamon.desktop.privacy|remember-recent-files|false"
    "Disable screensaver idle start;org.cinnamon.desktop.session|idle-delay|uint32 0;org.cinnamon.desktop.screensaver|idle-activation-enabled|false"
    "Set calendar applet settings;org.cinnamon|date-format|'YYYY-MM-DD';org.cinnamon.desktop.interface|clock-show-date|false;org.cinnamon.desktop.interface|clock-show-seconds|false"
)
