#!/usr/bin/env bash
# shellcheck disable=SC2034

SYSTEM_PANEL_GSETTINGS=(
    "org.cinnamon|enabled-applets|['panel1:left:0:menu@cinnamon.org:0', 'panel1:left:1:separator@cinnamon.org:1', 'panel1:left:2:grouped-window-list@cinnamon.org:2', 'panel1:right:8:systray@cinnamon.org:3', 'panel1:right:10:notifications@cinnamon.org:5', 'panel1:right:11:printers@cinnamon.org:6', 'panel1:right:12:removable-drives@cinnamon.org:7', 'panel1:right:13:keyboard@cinnamon.org:8', 'panel1:right:15:network@cinnamon.org:10', 'panel1:right:16:sound@cinnamon.org:11', 'panel1:right:17:power@cinnamon.org:12', 'panel1:right:18:calendar@cinnamon.org:13', 'panel1:right:19:cornerbar@cinnamon.org:14', 'panel1:right:2:wireguard@nicoulaj.net:20', 'panel1:right:0:xapp-status@cinnamon.org:22']"
    "org.cinnamon|no-adjacent-panel-barriers|false"
    "org.cinnamon|panel-edit-mode|false"
    "org.cinnamon|panel-launchers-draggable|true"
    "org.cinnamon|panel-scale-text-icons|true"
    "org.cinnamon|panel-zone-icon-sizes|'[{\"panelId\": 1, \"left\": 65, \"center\": 0, \"right\": 24}]'"
    "org.cinnamon|panel-zone-symbolic-icon-sizes|'[{\"panelId\": 1, \"left\": 48, \"center\": 28, \"right\": 30}]'"
    "org.cinnamon|panel-zone-text-sizes|'[{\"panelId\": 1, \"left\": 0.0, \"center\": 0.0, \"right\": 0.0}]'"
    "org.cinnamon|panels-autohide|['1:false']"
    "org.cinnamon|panels-enabled|['1:0:bottom']"
    "org.cinnamon|panels-height|['1:80']"
    "org.cinnamon|panels-hide-delay|['1:0']"
    "org.cinnamon|panels-show-delay|['1:0']"
)
