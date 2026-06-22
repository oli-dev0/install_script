#!/usr/bin/env bash

init_logging() {
    local timestamp
    local suffix=""

    timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"

    mkdir -p "$ROOT_DIR/logs"
    mkdir -p "$ROOT_DIR/backups"

    while true; do
        LOG_FILE="$ROOT_DIR/logs/install_${timestamp}${suffix}.log"
        BACKUP_RUN_DIR="$ROOT_DIR/backups/${timestamp}${suffix}"

        if [[ ! -e "$LOG_FILE" ]] && mkdir "$BACKUP_RUN_DIR" 2>/dev/null; then
            break
        fi

        if [[ -z "$suffix" ]]; then
            suffix="_2"
        else
            suffix="_$(( ${suffix#_} + 1 ))"
        fi
    done

    touch "$LOG_FILE"

    log_info "Linux Mint Bootstrap started"
    log_info "root_dir: $ROOT_DIR"
    log_info "config_file: $CONFIG_FILE"
    log_info "log_file: $LOG_FILE"
    log_info "backup_dir: $BACKUP_RUN_DIR"
    log_info "dry_run: $DRY_RUN"
    log_info "yes_mode: $YES_MODE"
    log_info "only_section: ${ONLY_SECTION:-all}"
}

log_line() {
    local level="$1"
    local message="$2"
    local timestamp

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '[%s] [%s] %s\n' "$timestamp" "$level" "$message" >> "$LOG_FILE"
}

log_info() {
    log_line "INFO" "$1"
}

log_success() {
    log_line "SUCCESS" "$1"
}

log_warning() {
    log_line "WARNING" "$1"
}

log_error() {
    log_line "ERROR" "$1"
}

log_skipped() {
    log_line "SKIPPED" "$1"
}

log_command_block() {
    local title="$1"
    local content="$2"

    {
        echo
        echo "----- $title -----"
        printf '%s\n' "$content"
        echo "----- end $title -----"
    } >> "$LOG_FILE"
}
