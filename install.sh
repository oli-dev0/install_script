#!/usr/bin/env bash

clear

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# shellcheck source=libs/bootstrap.sh
source "$ROOT_DIR/libs/bootstrap.sh"

main() {
    parse_args "$@"
    validate_only_section
    init_directories
    init_logging
    load_config

    print_app_header
    warn_if_not_linux_mint_cinnamon

    if ! ask_yes_no "Do you want to start the install?" "y"; then
        log_info "Install cancelled by user"
        echo "Install cancelled."
        exit 0
    fi

    request_sudo

    run_all_sections

    print_summary
    log_info "Install finished"
}

main "$@"
