#!/usr/bin/env bash

apps_apt_cache_is_clean() {
    ! find /var/cache/apt/archives -maxdepth 1 -type f \( -name '*.deb' -o -name '*.bin' \) | grep -q .
}

apps_autoremove_is_not_needed() {
    ! sudo apt-get -s autoremove | grep -Eq '^Remv '
}

apps_apt_update_completed() {
    [[ -f "$BACKUP_RUN_DIR/apps-apt-update.done" ]]
}

run_apps_apt_update() {
    sudo apt-get update
    touch "$BACKUP_RUN_DIR/apps-apt-update.done"
}

APPS_CUSTOM_STEPS=(
    "Update apt package index|run_apps_apt_update|apps_apt_update_completed|critical"
)

for app in "${APT_APPS[@]}"; do
    APPS_CUSTOM_STEPS+=("Install $app|sudo apt install -y $app|dpkg -s $app|critical")
done

APPS_CUSTOM_STEPS+=(
    "Clean apt cache|sudo apt-get clean|apps_apt_cache_is_clean|optional"
    "Remove unused apt packages|sudo apt-get autoremove -y|apps_autoremove_is_not_needed|optional"
)

section_start "Application Installs" "$(declared_array_length "APPS_CUSTOM_STEPS")"

run_custom_steps_from_entries "APPS_CUSTOM_STEPS"

section_end "Application Installs"
