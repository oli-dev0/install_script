#!/usr/bin/env bash

warn_if_not_linux_mint_cinnamon() {
    local os_name=""
    local desktop=""

    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        os_name="${NAME:-}"
    fi

    desktop="${XDG_CURRENT_DESKTOP:-}"

    if [[ "$os_name" == *"Linux Mint"* && "$desktop" == *"Cinnamon"* ]]; then
        log_success "Detected Linux Mint Cinnamon"
        return 0
    fi

    echo -e "${YELLOW}${ICON_WARN} Warning:${RESET} This script is designed for Linux Mint Cinnamon."
    echo "Detected OS: ${os_name:-unknown}"
    echo "Detected desktop: ${desktop:-unknown}"
    echo

    log_warning "Non-target system detected. OS=${os_name:-unknown} desktop=${desktop:-unknown}"

    if ! ask_yes_no "Continue anyway?" "n"; then
        log_info "Stopped because system is not Linux Mint Cinnamon"
        echo "Stopped."
        exit 1
    fi
}

request_sudo() {
    local sudo_password

    echo
    echo "Some steps may require sudo."
    echo "Checking sudo access now."
    echo

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}${ICON_SKIP} Dry-run: skipping sudo authentication${RESET}"
        log_info "DRY_RUN: skipping sudo -v"
        return 0
    fi

    if sudo -n -v 2>/dev/null; then
        echo -e "${BLUE}${ICON_ALREADY} sudo already authenticated${RESET}"
        log_success "sudo authentication already available"
        return 0
    fi

    echo "Enter your sudo password. Nothing will be shown while typing."
    read -r -s -p "[sudo] password for $USER: " sudo_password
    echo

    if printf '%s\n' "$sudo_password" | sudo -S -p '' -v; then
        unset sudo_password
        log_success "sudo authentication successful"
        return 0
    fi

    unset sudo_password
    echo -e "${RED}${ICON_ERROR} sudo authentication failed${RESET}"
    log_error "sudo authentication failed"
    exit 1
}

backup_file() {
    local source_file="$1"
    local relative_path
    local destination

    if [[ ! -e "$source_file" ]]; then
        log_warning "Backup skipped, file does not exist: $source_file"
        return 0
    fi

    relative_path="${source_file#/}"
    destination="$BACKUP_RUN_DIR/$relative_path"

    mkdir -p "$(dirname "$destination")"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY_RUN: would backup $source_file to $destination"
        return 0
    fi

    cp -a "$source_file" "$destination"
    log_success "Backed up $source_file to $destination"
}
