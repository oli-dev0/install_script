#!/usr/bin/env bash
# shellcheck disable=SC2034

required_commands apt-get dpkg find grep sudo touch

apps_apt_cache_is_clean() {
    ! find /var/cache/apt/archives -maxdepth 1 -type f \( -name '*.deb' -o -name '*.bin' \) | grep -q .
}

apps_autoremove_is_not_needed() {
    ! sudo apt-get -s autoremove | grep -Eq '^Remv '
}

apt_package_is_installed() {
    local package="$1"

    dpkg -s "$package" >/dev/null 2>&1
}

install_apt_package() {
    local package="$1"

    sudo apt-get install -y "$package"
}

run_apt_package_step() {
    local package="$1"
    local quoted_package

    quoted_package="$(shell_quote "$package")"

    run_step \
        "Install $package" \
        "install_apt_package $quoted_package" \
        "apt_package_is_installed $quoted_package" \
        "critical"
}

apps_apt_update_completed() {
    [[ -f "$BACKUP_RUN_DIR/apps-apt-update.done" ]]
}

run_apps_apt_update() {
    sudo apt-get update
    touch "$BACKUP_RUN_DIR/apps-apt-update.done"
}

clean_apps_apt_cache() {
    sudo apt-get clean
}

remove_unused_apt_packages() {
    sudo apt-get autoremove -y
}

APPS_PRE_INSTALL_STEPS=(
    "Update apt package index|run_apps_apt_update|apps_apt_update_completed|critical"
)

APPS_POST_INSTALL_STEPS=(
    "Clean apt cache|clean_apps_apt_cache|apps_apt_cache_is_clean|optional"
    "Remove unused apt packages|remove_unused_apt_packages|apps_autoremove_is_not_needed|optional"
)

APPS_SECTION_TOTAL=$(( \
    ${#APT_APPS[@]} + \
    $(declared_array_length "APPS_PRE_INSTALL_STEPS") + \
    $(declared_array_length "APPS_POST_INSTALL_STEPS") \
))

section_start "Application Installs" "$APPS_SECTION_TOTAL"

run_custom_steps_from_entries "APPS_PRE_INSTALL_STEPS"

for app in "${APT_APPS[@]}"; do
    run_apt_package_step "$app"
done

run_custom_steps_from_entries "APPS_POST_INSTALL_STEPS"

section_end "Application Installs"
