#!/bin/bash

##############################################################################
# System Update and CopyQ Launcher Script with Auto-Paste Disabled
# This script updates the system and launches CopyQ with auto-paste disabled
# Usage: ./system_update_copyq.sh
##############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

##############################################################################
# Function Definitions
##############################################################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

check_root_for_apt() {
    if [[ $EUID -ne 0 ]]; then
        print_warning "apt commands require root privileges"
        print_info "Attempting to use sudo for apt operations..."
        return 0
    fi
    print_success "Running with root privileges"
}

check_internet_connection() {
    print_info "Checking internet connection..."
    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Internet connection verified"
        return 0
    else
        print_error "No internet connection detected"
        return 1
    fi
}

check_flatpak_installed() {
    print_info "Checking if Flatpak is installed..."
    
    if ! command -v flatpak &> /dev/null; then
        print_error "Flatpak is not installed"
        print_info "Installing Flatpak..."
        
        if [[ $EUID -eq 0 ]]; then
            apt update && apt install -y flatpak
        else
            sudo apt update && sudo apt install -y flatpak
        fi
        
        print_success "Flatpak installed successfully"
    else
        print_success "Flatpak is already installed"
    fi
}

check_copyq_installed() {
    print_info "Checking if CopyQ Flatpak is installed..."
    
    if flatpak info com.github.hluk.copyq &> /dev/null; then
        print_success "CopyQ Flatpak is already installed"
        return 0
    else
        print_warning "CopyQ Flatpak is not installed"
        return 1
    fi
}

update_system() {
    print_header "Step 1: Updating System"
    
    print_info "Running: apt update"
    
    if [[ $EUID -eq 0 ]]; then
        apt update || {
            print_error "apt update failed"
            return 1
        }
    else
        sudo apt update || {
            print_error "apt update failed"
            return 1
        }
    fi
    
    print_success "apt update completed"
    
    print_info "Running: apt upgrade -y"
    
    if [[ $EUID -eq 0 ]]; then
        apt upgrade -y || {
            print_error "apt upgrade failed"
            return 1
        }
    else
        sudo apt upgrade -y || {
            print_error "apt upgrade failed"
            return 1
        }
    fi
    
    print_success "apt upgrade completed successfully"
}

install_copyq_flatpak() {
    print_header "Step 2: Installing CopyQ Flatpak"
    
    print_info "Installing CopyQ from Flathub..."
    
    if ! flatpak install -y flathub com.github.hluk.copyq; then
        print_error "Failed to install CopyQ Flatpak"
        return 1
    fi
    
    print_success "CopyQ Flatpak installed successfully"
}

disable_copyq_autopaste() {
    print_header "Step 2.5: Configuring CopyQ Settings"
    
    local copyq_config_dir="$HOME/.var/app/com.github.hluk.copyq/config"
    local copyq_config_file="$copyq_config_dir/copyq/copyq.conf"
    
    print_info "Locating CopyQ configuration directory..."
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$copyq_config_dir" ]]; then
        print_info "Creating CopyQ config directory..."
        mkdir -p "$copyq_config_dir"
        print_success "Config directory created"
    fi
    
    # Check if config file exists
    if [[ ! -f "$copyq_config_file" ]]; then
        print_info "Creating new CopyQ configuration file..."
        
        # Create the config directory structure
        mkdir -p "$(dirname "$copyq_config_file")"
        
        # Create config file with auto-paste disabled
        cat > "$copyq_config_file" << 'EOF'
[General]
activate_closes=false
activate_focuses=true
always_on_top=false
check_selection=false
close_on_mouse_move=false
confirm_exit=true
copy_clipboard=true
copy_selection=true
disable_clipboard_store=false
editor=
expire_tab=-1
filter_case_insensitive=true
hide_main_window=true
hide_main_window_in_taskbar=true
hide_tabs=false
item_popup_interval=0
max_process_manager_rows=100
move_tab_on_mouse_move=false
notification_horizontal_offset=10
notification_position=3
notification_vertical_offset=10
number_search=false
paste_on_selection_returns_to_previous=false
run_script=
save_filter_history=true
save_unsaved_tabs=true
show_log=false
show_number=false
show_tray_menu=false
startup_commands=
tab=Default

[Shortcuts]
activate_paste_mode=
autocomplete_next=Ctrl+Down
autocomplete_previous=Ctrl+Up
change_clipboard_mode_next_character=
change_clipboard_mode_next_word=
change_clipboard_mode_previous_word=
clear_tab=Ctrl+L
close_main_window=
close_tab=Alt+W
close_tab_all=
close_tab_all_except_current=
close_tab_left=
close_tab_right=
copy_next_to_clipboard=
copy_previous_to_clipboard=
delete_item=Del
delete_tab=
down=Ctrl+K
edit_item=F2
edit_new=Ctrl+N
exit_application=Ctrl+Q
export_tab=
find_items=Ctrl+F
help=
import_tab=
increase_item_height=
insert_item=Alt+I
item_menu=
load_commands=
move_item_down=
move_item_up=
move_to_clipboard=Ctrl+M
move_up=
new_tab=Ctrl+T
next_tab=Right
notification_action_activated=
open_action_dialog=F1
paste_and_pop=Ctrl+Alt+V
paste_mode=Ctrl+Shift+V
previous_tab=Left
print_items=
remove_command=
remove_format=
rename_tab=
reverse_item_order=
rotate_item_selections=
search=Ctrl+J
show_log=
show_main_window=Ctrl+Alt+C
sort_selected_items=
system_run=Ctrl+R
toggle_clip_mode=
toggle_clipboard=Alt+0
toggle_selection=Ctrl+Shift+M
unload_commands=
up=Ctrl+K

[Plugins]
copyq_clipboard=enabled
copyq_itemdata=enabled
copyq_itemimage=enabled
copyq_itemtext=enabled
copyq_itemnumber=enabled
copyq_itemsync=enabled
copyq_qml=enabled

[Behavior]
auto_paste=false
auto_start=true
close_on_unfocus=false
copy_whole_line=false
move_on_selection=false
show_tray_icon=true
transparency=0
transparency_focused=0

EOF
        
        print_success "CopyQ configuration file created with auto-paste disabled"
    else
        print_info "CopyQ configuration file already exists"
        print_info "Updating auto-paste setting..."
        
        # Update or add the auto_paste setting
        if grep -q "^auto_paste=" "$copyq_config_file"; then
            sed -i 's/^auto_paste=.*/auto_paste=false/' "$copyq_config_file"
            print_success "auto_paste setting updated to false"
        else
            # Add the setting if it doesn't exist
            echo "auto_paste=false" >> "$copyq_config_file"
            print_success "auto_paste setting added and set to false"
        fi
    fi
}

launch_copyq() {
    print_header "Step 3: Launching CopyQ"
    
    print_info "Starting CopyQ clipboard manager..."
    print_info "Auto-paste is disabled"
    
    if ! flatpak run com.github.hluk.copyq; then
        print_error "Failed to launch CopyQ"
        return 1
    fi
    
    print_success "CopyQ launched successfully"
}

print_completion_info() {
    print_header "Process Complete!"
    
    echo -e "${GREEN}System has been updated and CopyQ has been launched.${NC}\n"
    
    echo "Summary of actions performed:"
    echo "1. ✓ System packages updated (apt update)"
    echo "2. ✓ System packages upgraded (apt upgrade)"
    echo "3. ✓ CopyQ Flatpak installed/launched"
    echo "4. ✓ Auto-paste disabled in CopyQ configuration"
    echo ""
    echo "CopyQ is now running as your clipboard manager"
    echo "Auto-paste has been disabled - items will not automatically paste"
    echo ""
    echo "Configuration file location:"
    echo "  $HOME/.var/app/com.github.hluk.copyq/config/copyq/copyq.conf"
}

##############################################################################
# Main Script Execution
##############################################################################

main() {
    print_header "System Update and CopyQ Launcher"
    
    # Check internet connection
    if ! check_internet_connection; then
        print_error "Cannot proceed without internet connection"
        exit 1
    fi
    
    # Check if running with appropriate privileges
    check_root_for_apt
    
    # Check if Flatpak is installed
    check_flatpak_installed
    
    # Update system
    if ! update_system; then
        print_error "System update failed"
        exit 1
    fi
    
    echo ""
    
    # Check if CopyQ needs to be installed
    if ! check_copyq_installed; then
        if ! install_copyq_flatpak; then
            print_error "CopyQ installation failed"
            exit 1
        fi
    fi
    
    echo ""
    
    # Disable auto-paste
    if ! disable_copyq_autopaste; then
        print_warning "Failed to disable auto-paste, continuing anyway..."
    fi
    
    echo ""
    
    # Launch CopyQ
    if ! launch_copyq; then
        print_error "CopyQ launch failed"
        exit 1
    fi
    
    echo ""
    
    # Print completion info
    print_completion_info
}

##############################################################################
# Script Entry Point
##############################################################################

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script updates your system and launches CopyQ with auto-paste disabled"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -u, --update     Only run system update (skip CopyQ)"
    echo "  -c, --copyq      Only launch CopyQ (skip system update)"
    echo "  -d, --disable    Only disable auto-paste (skip system update)"
    echo ""
    echo "Examples:"
    echo "  $0                # Run full update and launch CopyQ"
    echo "  $0 --update       # Only update system packages"
    echo "  $0 --copyq        # Only launch CopyQ"
    echo "  $0 --disable      # Only disable auto-paste"
    exit 0
fi

# Handle optional arguments
if [[ "$1" == "-u" ]] || [[ "$1" == "--update" ]]; then
    print_header "System Update Only Mode"
    check_root_for_apt
    if ! update_system; then
        print_error "System update failed"
        exit 1
    fi
    print_success "System update completed"
    exit 0
elif [[ "$1" == "-c" ]] || [[ "$1" == "--copyq" ]]; then
    print_header "CopyQ Launch Only Mode"
    check_flatpak_installed
    if ! check_copyq_installed; then
        print_info "CopyQ not installed, installing now..."
        if ! install_copyq_flatpak; then
            print_error "CopyQ installation failed"
            exit 1
        fi
    fi
    disable_copyq_autopaste
    if ! launch_copyq; then
        print_error "CopyQ launch failed"
        exit 1
    fi
    print_success "CopyQ launched successfully with auto-paste disabled"
    exit 0
elif [[ "$1" == "-d" ]] || [[ "$1" == "--disable" ]]; then
    print_header "Disable Auto-Paste Only Mode"
    if ! disable_copyq_autopaste; then
        print_error "Failed to disable auto-paste"
        exit 1
    fi
    print_success "Auto-paste has been disabled"
    exit 0
fi

# Run main function (full mode)
main "$@"
