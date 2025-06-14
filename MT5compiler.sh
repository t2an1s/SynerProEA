#!/bin/bash

# ================================================================
# SynerProEA - MQL5 Compilation Script
# ================================================================
# This script compiles MQL5 Expert Advisors with comprehensive
# error handling, logging, and diagnostic capabilities.
# 
# Features:
# - UTF-16 log file parsing with proper encoding handling
# - Robust error and warning counting with fallback methods
# - Detailed compilation diagnostics and reporting
# - Support for multiple EA files with individual status tracking
# - Color-coded output for better readability
# - Comprehensive logging with timestamps
# ================================================================

set -euo pipefail

# Color codes for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD_LOGS_DIR="${SCRIPT_DIR}/build_logs"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly MAIN_LOG="${BUILD_LOGS_DIR}/compilation_${TIMESTAMP}.log"

# MetaTrader paths - adjust these for your system
readonly BOTTLE="MT5"
readonly PREFIX="$HOME/Library/Application Support/CrossOver/Bottles/$BOTTLE"
readonly CXSTART_BINARY="/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxstart"
readonly METAEDITOR_PATH="C:/Program Files/MetaTrader 5/MetaEditor64.exe"
readonly MQL5_INCLUDE_PATH="C:/Program Files/MetaTrader 5/MQL5/Include"

# EA files to compile
EA_FILES=(SynPropEA1.mq5 SynPropEA2.mq5)

# Global counters
declare -i TOTAL_COMPILED=0
declare -i TOTAL_SUCCESS=0
declare -i TOTAL_FAILED=0

# ================================================================
# Utility Functions
# ================================================================

log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[$timestamp] [$level] $message" | tee -a "$MAIN_LOG"
}

log_info() {
    log_message "INFO" "${CYAN}$*${NC}"
}

log_success() {
    log_message "SUCCESS" "${GREEN}$*${NC}"
}

log_warning() {
    log_message "WARNING" "${YELLOW}$*${NC}"
}

log_error() {
    log_message "ERROR" "${RED}$*${NC}"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        log_message "DEBUG" "${PURPLE}$*${NC}"
    fi
}

print_separator() {
    echo -e "${BLUE}================================================================${NC}"
}

print_header() {
    print_separator
    echo -e "${WHITE}$1${NC}"
    print_separator
}

# ================================================================
# Setup Functions
# ================================================================

setup_environment() {
    log_info "Setting up compilation environment..."
    
    # Create build logs directory
    mkdir -p "$BUILD_LOGS_DIR"
    
    # Verify CrossOver cxstart exists
    if [[ ! -f "$CXSTART_BINARY" ]]; then
        log_error "CrossOver cxstart not found at: $CXSTART_BINARY"
        log_error "Please check if CrossOver is installed and the MT5 bottle exists"
        exit 1
    fi
    
    # Check if we're running on macOS with CrossOver
    if [[ "$(uname)" == "Darwin" ]]; then
        log_info "Detected macOS environment - using CrossOver cxstart for MT5"
        log_info "cxstart binary: $CXSTART_BINARY"
        log_info "MetaEditor path: $METAEDITOR_PATH"
        log_info "Target bottle: $BOTTLE"
    fi
    
    log_success "Environment setup completed"
}

# ================================================================
# Compilation Functions
# ================================================================

sanitize_variable() {
    local var="$1"
    # Remove newlines, carriage returns, and extra spaces
    echo "$var" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

is_valid_number() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]]
}

parse_compilation_log() {
    local log_file="$1"
    local errors=0
    local warnings=0
    
    log_debug "Parsing compilation log: $log_file"
    
    if [[ ! -f "$log_file" ]]; then
        log_warning "Log file not found: $log_file"
        return 1
    fi
    
    # Try to detect file encoding and convert if necessary
    local temp_log="${log_file}.utf8"
    
    # Check if file is UTF-16 and convert to UTF-8
    if file "$log_file" | grep -q "UTF-16"; then
        log_debug "Converting UTF-16 log file to UTF-8"
        if command -v iconv &> /dev/null; then
            iconv -f UTF-16 -t UTF-8 "$log_file" > "$temp_log" 2>/dev/null || {
                log_warning "Failed to convert UTF-16 file, trying direct parsing"
                cp "$log_file" "$temp_log"
            }
        else
            log_warning "iconv not available, trying direct parsing"
            cp "$log_file" "$temp_log"
        fi
    else
        cp "$log_file" "$temp_log"
    fi
    
    # Extract summary line "Result: X errors, Y warnings"
    local result_line
    result_line=$(grep -i "Result:" "$temp_log" | tail -1 || echo "")
    if [[ -n "$result_line" ]]; then
        # Parse error and warning counts from the summary
        local error_count warning_count
        error_count=$(echo "$result_line" | sed -E 's/.*Result:[[:space:]]*([0-9]+) errors,.*/\1/')
        warning_count=$(echo "$result_line" | sed -E 's/.*Result:[[:space:]]*[0-9]+ errors,[[:space:]]*([0-9]+) warnings.*/\1/')
        errors=$error_count
        warnings=$warning_count
        log_debug "Parsed Result line: '$result_line'"
        log_debug "Extracted error count: $errors"
        log_debug "Extracted warning count: $warnings"
    else
        log_warning "parse_compilation_log: Could not find summary Result line. Falling back to manual count."
        # Manual count fallback
        local manual_errors manual_warnings
        manual_errors=$(grep -c -i "error\|fehler" "$temp_log" 2>/dev/null || echo "0")
        manual_warnings=$(grep -c -i "warning\|warnung" "$temp_log" 2>/dev/null || echo "0")
        manual_errors=$(sanitize_variable "$manual_errors")
        manual_warnings=$(sanitize_variable "$manual_warnings")
        if is_valid_number "$manual_errors"; then errors=$manual_errors; fi
        if is_valid_number "$manual_warnings"; then warnings=$manual_warnings; fi
        log_debug "Manual count - Errors: $errors, Warnings: $warnings"
    fi
    
    # Clean up temporary file
    rm -f "$temp_log"
    
    # Return the counts (using global variables for simplicity)
    PARSED_ERRORS="$errors"
    PARSED_WARNINGS="$warnings"
    
    log_debug "Final parsed counts - Errors: $PARSED_ERRORS, Warnings: $PARSED_WARNINGS"
    return 0
}

compile_ea() {
    local ea_file="$1"
    local ea_name="${ea_file%.mq5}"
    local log_file="${BUILD_LOGS_DIR}/${ea_name}_${TIMESTAMP}.log"
    
    log_info "Compiling $ea_file..."
    
    # Check if source file exists
    if [[ ! -f "$ea_file" ]]; then
        log_error "Source file not found: $ea_file"
        return 1
    fi
    
    # Prepare compilation command
    local compile_cmd
    if [[ "$(uname)" == "Darwin" ]] && [[ -f "$CXSTART_BINARY" ]]; then
        # Use cxstart with bottle option - this is the proper CrossOver way
        local src_win_path="Z:$SCRIPT_DIR/$ea_file"
        local log_win_path="Z:$log_file"
        
        compile_cmd="$CXSTART_BINARY --bottle \"$BOTTLE\" \"$METAEDITOR_PATH\" /compile:\"$src_win_path\" /log:\"$log_win_path\""
        log_debug "Using cxstart with bottle: $BOTTLE"
    else
        compile_cmd="\"$METAEDITOR_PATH\" /compile:\"$SCRIPT_DIR/$ea_file\" /log:\"$log_file\""
    fi
    
    log_debug "Compilation command: $compile_cmd"
    
    # Execute compilation
    local compile_exit_code=0
    eval "$compile_cmd" &>/dev/null || compile_exit_code=$?
    
    # If compilation failed with CrossOver, provide helpful guidance
    if [[ "$compile_exit_code" -ne 0 && "$(uname)" == "Darwin" ]]; then
        log_warning "CrossOver compilation failed. This might be due to bottle configuration issues."
        log_info "Alternative compilation methods:"
        log_info "1. Open MetaTrader 5 in CrossOver and use MetaEditor GUI"
        log_info "2. Check if 'default' bottle exists or create one"
        log_info "3. Try running: open -a 'CrossOver' and manually compile"
        log_info "4. Verify MT5 bottle is properly configured"
    fi
    
    # Wait a moment for log file to be written
    sleep 2
    
    # Parse compilation results
    local errors=0 warnings=0
    if parse_compilation_log "$log_file"; then
        errors="$PARSED_ERRORS"
        warnings="$PARSED_WARNINGS"
    else
        log_warning "Failed to parse log file for $ea_file"
        # Use exit code as fallback indicator
        if [[ "$compile_exit_code" -ne 0 ]]; then
            errors=1
        fi
    fi
    
    # Display results
    local status_color status_text
    if [[ "$errors" -eq 0 ]]; then
        status_color="$GREEN"
        status_text="✅ SUCCESS"
        ((TOTAL_SUCCESS++))
    else
        status_color="$RED"
        status_text="❌ FAILED"
        ((TOTAL_FAILED++))
    fi
    
    echo -e "${status_color}${status_text}${NC} - ${WHITE}$ea_file${NC}"
    echo -e "  📊 Errors: ${RED}$errors${NC} | Warnings: ${YELLOW}$warnings${NC}"
    echo -e "  📄 Log: $log_file"
    
    # Show compilation details if there are issues
    if [[ "$errors" -gt 0 || "$warnings" -gt 0 ]]; then
        echo -e "  ${CYAN}Compilation Details:${NC}"
        if [[ -f "$log_file" ]]; then
            # Show relevant error/warning lines
            local temp_log="${log_file}.display"
            
            # Convert log file for display if needed
            if file "$log_file" | grep -q "UTF-16"; then
                if command -v iconv &> /dev/null; then
                    iconv -f UTF-16 -t UTF-8 "$log_file" > "$temp_log" 2>/dev/null || cp "$log_file" "$temp_log"
                else
                    cp "$log_file" "$temp_log"
                fi
            else
                cp "$log_file" "$temp_log"
            fi
            
            # Show error and warning lines
            if [[ "$errors" -gt 0 ]]; then
                echo -e "    ${RED}Errors:${NC}"
                grep -i "error\|fehler" "$temp_log" 2>/dev/null | head -5 | sed 's/^/      /' || echo "      No specific error details found"
            fi
            
            if [[ "$warnings" -gt 0 ]]; then
                echo -e "    ${YELLOW}Warnings:${NC}"
                grep -i "warning\|warnung" "$temp_log" 2>/dev/null | head -3 | sed 's/^/      /' || echo "      No specific warning details found"
            fi
            
            rm -f "$temp_log"
        else
            echo -e "    ${RED}Log file not available for detailed analysis${NC}"
        fi
    fi
    
    echo # Empty line for readability
    
    return $errors
}

# ================================================================
# Main Compilation Process
# ================================================================

compile_all_eas() {
    print_header "Starting MQL5 Expert Advisor Compilation"
    
    log_info "Starting compilation of ${#EA_FILES[@]} Expert Advisor(s)"
    
    for ea_file in "${EA_FILES[@]}"; do
        ((TOTAL_COMPILED++))
        compile_ea "$ea_file"
    done
}

# ================================================================
# Results Summary
# ================================================================

show_summary() {
    print_header "Compilation Summary"
    
    echo -e "${WHITE}📈 Compilation Statistics:${NC}"
    echo -e "  Total EAs processed: ${BLUE}$TOTAL_COMPILED${NC}"
    echo -e "  Successful: ${GREEN}$TOTAL_SUCCESS${NC}"
    echo -e "  Failed: ${RED}$TOTAL_FAILED${NC}"
    echo
    
    if [[ "$TOTAL_FAILED" -eq 0 ]]; then
        echo -e "${GREEN}🎉 All Expert Advisors compiled successfully!${NC}"
        log_success "All compilations completed successfully"
    else
        echo -e "${RED}⚠️  Some Expert Advisors failed to compile${NC}"
        echo -e "Check the individual log files in ${BUILD_LOGS_DIR}/ for detailed error information"
        log_warning "$TOTAL_FAILED out of $TOTAL_COMPILED compilations failed"
    fi
    
    echo
    echo -e "${CYAN}📂 Build artifacts location: ${BUILD_LOGS_DIR}/${NC}"
    echo -e "${CYAN}📋 Main log file: ${MAIN_LOG}${NC}"
    
    print_separator
}

# ================================================================
# Main Script Execution
# ================================================================

main() {
    local start_time
    start_time=$(date +%s)
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                export DEBUG=1
                log_info "Debug mode enabled"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--debug] [--help]"
                echo "  --debug    Enable debug output"
                echo "  --help     Show this help message"
                exit 0
                ;;
            *)
                log_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Initialize
    print_header "SynerProEA - MQL5 Compilation System"
    log_info "Compilation started at $(date)"
    
    # Setup environment
    setup_environment
    
    # Compile all EAs
    compile_all_eas
    
    # Show final summary
    show_summary
    
    # Calculate total execution time
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "Compilation completed in ${duration} seconds"
    
    # Exit with appropriate code
    if [[ "$TOTAL_FAILED" -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
