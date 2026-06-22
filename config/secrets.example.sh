#!/usr/bin/env bash
# shellcheck disable=SC2034

# Copy this file to config/secrets.sh and fill in your personal values.

SECRET_GIT_USER_NAME=""
SECRET_GIT_USER_EMAIL=""
SECRET_GIT_IGNORE_GLOBAL_ENTRIES=(
    "*.swp"
    "*.swo"
)

# Secret files expected by the installer:
# - config/secrets/hosts
# - config/secrets/ssh/config
# - config/secrets/ssh/id_ed25519
# - config/secrets/ssh/id_ed25519.pub

SECRET_NETWORK_WIFI_PROFILES=(
    # "Connection Name|SSID|Password"
)
