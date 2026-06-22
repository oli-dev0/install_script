#!/usr/bin/env bash

TOTAL_STEPS=0
SUCCESS_STEPS=0
ALREADY_STEPS=0
SKIPPED_STEPS=0
FAILED_STEPS=0
CONTINUED_FAILURES=0
DRY_RUN_STEPS=0

# shellcheck disable=SC2034
CURRENT_SECTION_TITLE=""
CURRENT_SECTION_STEP=0
CURRENT_SECTION_TOTAL=0

increment_total() {
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
}

increment_success() {
    SUCCESS_STEPS=$((SUCCESS_STEPS + 1))
}

increment_already() {
    ALREADY_STEPS=$((ALREADY_STEPS + 1))
}

increment_skipped() {
    SKIPPED_STEPS=$((SKIPPED_STEPS + 1))
}

increment_failed() {
    FAILED_STEPS=$((FAILED_STEPS + 1))
}

increment_continued_failure() {
    CONTINUED_FAILURES=$((CONTINUED_FAILURES + 1))
}

increment_dry_run() {
    DRY_RUN_STEPS=$((DRY_RUN_STEPS + 1))
}

section_start() {
    local title="$1"
    local total_steps="$2"

    CURRENT_SECTION_TITLE="$title"
    CURRENT_SECTION_STEP=0
    CURRENT_SECTION_TOTAL="$total_steps"

    echo
    echo -e "${BOLD}${CYAN}========================================${RESET}"
    echo -e "${BOLD}${CYAN}          $title${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}"

    log_info "SECTION START: $title"
    log_info "SECTION TOTAL STEPS: $total_steps"
}

section_end() {
    local title="$1"

    echo
    echo -e "${GREEN}${ICON_SUCCESS} Finished $title [$CURRENT_SECTION_STEP/$CURRENT_SECTION_TOTAL]${RESET}"

    log_info "SECTION END: $title"
    log_info "SECTION PROGRESS: $CURRENT_SECTION_STEP/$CURRENT_SECTION_TOTAL"

    # shellcheck disable=SC2034
    CURRENT_SECTION_TITLE=""
    CURRENT_SECTION_STEP=0
    CURRENT_SECTION_TOTAL=0
}

increment_section_step() {
    CURRENT_SECTION_STEP=$((CURRENT_SECTION_STEP + 1))
}

print_step_header() {
    local title="$1"

    echo
    if [[ "$CURRENT_SECTION_TOTAL" -gt 0 ]]; then
        echo -e "${BOLD}[${CURRENT_SECTION_STEP}/${CURRENT_SECTION_TOTAL}] ${ICON_RUN} $title${RESET}"
    else
        echo -e "${BOLD}${ICON_RUN} $title${RESET}"
    fi
}

print_summary() {
    echo
    echo -e "${BOLD}${CYAN}========================================${RESET}"
    echo -e "${BOLD}${CYAN}              Summary${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}"
    echo

    echo -e "Total steps:        ${BOLD}$TOTAL_STEPS${RESET}"
    echo -e "Success:            ${GREEN}$SUCCESS_STEPS${RESET}"
    echo -e "Already done:       ${BLUE}$ALREADY_STEPS${RESET}"
    echo -e "Skipped categories: ${YELLOW}$SKIPPED_STEPS${RESET}"
    echo -e "Failed:             ${RED}$FAILED_STEPS${RESET}"
    echo -e "Continued failures: ${YELLOW}$CONTINUED_FAILURES${RESET}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "Dry-run steps:      ${YELLOW}$DRY_RUN_STEPS${RESET}"
    fi

    echo
    echo "Log file:"
    echo "$LOG_FILE"

    echo
    echo "Backup folder:"
    echo -e "$BACKUP_RUN_DIR \n"

    log_info "Summary: total=$TOTAL_STEPS success=$SUCCESS_STEPS already=$ALREADY_STEPS skipped=$SKIPPED_STEPS failed=$FAILED_STEPS continued_failures=$CONTINUED_FAILURES dry_run=$DRY_RUN_STEPS"
}

exit_with_summary_status() {
    if (( CONTINUED_FAILURES > 0 )); then
        log_error "Install finished with continued failures"
        exit 2
    fi

    exit 0
}
