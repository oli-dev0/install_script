#!/usr/bin/env bash

run_step() {
    local title="$1"
    local change_cmd="$2"
    local check_cmd="$3"
    local criticality="${4:-optional}"

    local output=""
    local check_output=""
    local action_result=0
    local user_choice=0

    increment_total
    increment_section_step
    print_step_header "$title"

    log_info "STEP START: $title"
    log_info "CRITICALITY: $criticality"
    log_info "CHANGE CMD: $change_cmd"
    log_info "CHECK CMD: $check_cmd"

    if check_output="$(eval "$check_cmd" 2>&1)"; then
        echo -e "${BLUE}${ICON_ALREADY} Already done${RESET}"
        log_success "STEP ALREADY DONE: $title"
        log_command_block "check output: $title" "$check_output"
        increment_already
        return 0
    fi

    log_command_block "initial check failed output: $title" "$check_output"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}${ICON_SKIP} Dry-run: would run command${RESET}"
        log_info "DRY_RUN STEP: $title"
        increment_dry_run
        return 0
    fi

    while true; do
        output="$(eval "$change_cmd" 2>&1)"
        action_result=$?
        log_command_block "change output: $title" "$output"

        if [[ $action_result -eq 0 ]]; then
            if check_output="$(eval "$check_cmd" 2>&1)"; then
                echo -e "${GREEN}${ICON_SUCCESS} Success${RESET}"
                log_success "STEP SUCCESS: $title"
                log_command_block "final check output: $title" "$check_output"
                increment_success
                return 0
            fi

            log_command_block "final check failed output: $title" "$check_output"
        else
            log_error "CHANGE CMD FAILED: $title exit_code=$action_result"
        fi

        echo -e "${RED}${ICON_ERROR} Failed${RESET}"
        log_error "STEP FAILED: $title"

        ask_retry_continue_quit "$criticality"
        user_choice=$?

        case "$user_choice" in
            0)
                log_info "User chose retry: $title"
                echo "Retrying..."
                ;;
            1)
                log_warning "User chose continue after failure: $title"
                increment_failed
                increment_continued_failure
                return 0
                ;;
            2)
                log_error "User chose quit after failure: $title"
                increment_failed
                echo "Stopping."
                exit 1
                ;;
        esac
    done
}

run_manual_step() {
    local title="$1"
    local instructions="$2"
    local check_cmd="$3"
    local criticality="${4:-optional}"
    local user_choice=0

    increment_total
    increment_section_step
    print_step_header "$title"
    echo "$instructions"

    log_info "MANUAL STEP START: $title"
    log_info "INSTRUCTIONS: $instructions"
    log_info "CHECK CMD: $check_cmd"
    log_info "CRITICALITY: $criticality"

    if eval "$check_cmd" &>/dev/null; then
        echo -e "${BLUE}${ICON_ALREADY} Already done${RESET}"
        log_success "MANUAL STEP ALREADY DONE: $title"
        increment_already
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}${ICON_SKIP} Dry-run: manual step not required${RESET}"
        log_info "DRY_RUN MANUAL STEP: $title"
        increment_dry_run
        return 0
    fi

    if ask_yes_no "Have you completed this manual step?" "n" && eval "$check_cmd" &>/dev/null; then
        echo -e "${GREEN}${ICON_SUCCESS} Success${RESET}"
        log_success "MANUAL STEP SUCCESS: $title"
        increment_success
        return 0
    fi

    echo -e "${RED}${ICON_ERROR} Failed manual verification${RESET}"
    log_error "MANUAL STEP FAILED: $title"

    ask_retry_continue_quit "$criticality"
    user_choice=$?

    case "$user_choice" in
        0)
            run_manual_step "$title" "$instructions" "$check_cmd" "$criticality"
            ;;
        1)
            increment_failed
            increment_continued_failure
            return 0
            ;;
        2)
            increment_failed
            echo "Stopping."
            exit 1
            ;;
    esac
}

run_skipped_step() {
    local title="$1"
    local reason="$2"

    increment_total
    increment_section_step
    print_step_header "$title"

    echo -e "${YELLOW}${ICON_SKIP} Skipped: $reason${RESET}"
    log_warning "STEP SKIPPED: $title reason=$reason"
    increment_skipped
}
