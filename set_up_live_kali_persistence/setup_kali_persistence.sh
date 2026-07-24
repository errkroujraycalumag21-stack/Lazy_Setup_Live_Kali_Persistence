#!/bin/bash

##############################################################################
# Kali Linux USB Persistence Setup Script
# This script automates the process of setting up persistence on a USB drive
# Usage: sudo ./setup_kali_persistence.sh
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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
    print_success "Running with root privileges"
}

show_lsblk() {
    print_header "Available Block Devices"
    echo ""
    lsblk -d -o NAME,SIZE,TYPE,TRAN
    echo ""
}

select_usb_device() {
    local usb_device
    
    read -p "Enter USB device name (sda, sdb, sdc, etc.): " device_name
    
    # Ensure device name starts with /dev/
    if [[ $device_name == /dev/* ]]; then
        usb_device="$device_name"
    else
        usb_device="/dev/$device_name"
    fi
    
    echo "$usb_device"
}

validate_usb_device() {
    local usb_device=$1
    
    # Check if device exists
    if [[ ! -b "$usb_device" ]]; then
        print_error "Device $usb_device does not exist"
        return 1
    fi
    
    # Check if it's a valid USB device
    if ! lsblk -d "$usb_device" &>/dev/null; then
        print_error "$usb_device is not a valid block device"
        return 1
    fi
    
    print_success "Device $usb_device validated"
    return 0
}

confirm_device() {
    local usb_device=$1
    local device_info
    
    device_info=$(lsblk -d -o NAME,SIZE,TYPE "$usb_device" 2>/dev/null | tail -1)
    
    echo ""
    echo -e "${YELLOW}Device selected: $device_info${NC}"
    echo -e "${RED}WARNING: All data on $usb_device will be PERMANENTLY ERASED!${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        print_error "Operation cancelled by user"
        exit 1
    fi
    
    print_success "Device confirmed for formatting"
}

unmount_device() {
    local usb_device=$1
    
    print_info "Unmounting any mounted partitions on $usb_device..."
    
    # Unmount all partitions of the device
    for partition in "${usb_device}"*; do
        if [[ -b "$partition" ]] && mountpoint -q "$partition" 2>/dev/null; then
            if ! sudo umount "$partition" 2>/dev/null; then
                print_warning "Could not unmount $partition, attempting forced unmount..."
                sudo umount -l "$partition" 2>/dev/null || true
            fi
            print_success "Unmounted $partition"
        fi
    done
}

create_partition() {
    local usb_device=$1
    
    print_header "Step 1: Creating New Partition"
    print_info "Creating a new primary partition in remaining space..."
    
    # Using fdisk to create partition automatically
    sudo fdisk "$usb_device" <<EOF > /dev/null 2>&1
p
n
p


p
w
EOF
    
    # Wait for the system to recognize the new partition
    sleep 2
    
    print_success "Partition created successfully"
}

format_partition() {
    local usb_device=$1
    local partition_number="${usb_device}3"
    
    print_header "Step 2: Formatting Partition with ext4"
    print_info "Formatting $partition_number with ext4 filesystem..."
    
    # Wait for device to be ready
    sleep 2
    
    if ! sudo mkfs.ext4 -L persistence "$partition_number" 2>&1 | grep -q "done"; then
        print_error "Failed to format partition"
        return 1
    fi
    
    print_success "Partition formatted with ext4 (Label: persistence)"
}

setup_persistence() {
    local usb_device=$1
    local partition_number="${usb_device}3"
    local mount_point="/mnt/my_usb"
    
    print_header "Step 3: Configuring Persistence"
    
    # Create mount point
    print_info "Creating mount point at $mount_point..."
    sudo mkdir -pv "$mount_point"
    print_success "Mount point created"
    
    # Mount the partition
    print_info "Mounting partition $partition_number..."
    sudo mount -v "$partition_number" "$mount_point"
    print_success "Partition mounted successfully"
    
    # Create persistence configuration
    print_info "Creating persistence.conf file..."
    echo "/ union" | sudo tee "$mount_point/persistence.conf" > /dev/null
    print_success "persistence.conf created with configuration: '/ union'"
    
    # Unmount the partition
    print_info "Unmounting partition..."
    sudo umount -v "$partition_number"
    print_success "Partition unmounted successfully"
}

print_completion_info() {
    local usb_device=$1
    
    print_header "Setup Complete!"
    
    echo -e "${GREEN}Your Kali Linux USB persistence drive is ready!${NC}\n"
    
    echo "Next steps:"
    echo "1. Safely eject the USB drive from your computer"
    echo "2. Boot your system from the USB drive"
    echo "3. At the Kali boot menu, select 'Live USB Persistence'"
    echo "4. Your Kali system will now boot with persistence enabled"
    echo ""
    echo "Device configured: $usb_device"
    echo "Persistence partition: ${usb_device}3"
    echo "Configuration: / union"
}

##############################################################################
# Main Script Execution
##############################################################################

main() {
    print_header "Kali Linux USB Persistence Setup"
    
    # Check for root privileges
    check_root
    
    # Show available block devices
    show_lsblk
    
    # Get user input for USB device
    local usb_device
    usb_device=$(select_usb_device)
    
    echo ""
    print_info "Selected device: $usb_device"
    echo ""
    
    # Validate device
    if ! validate_usb_device "$usb_device"; then
        print_error "Invalid device selected"
        exit 1
    fi
    
    # Confirm device before proceeding
    confirm_device "$usb_device"
    
    # Unmount any existing partitions
    unmount_device "$usb_device"
    
    # Create partition
    create_partition "$usb_device"
    
    # Format partition
    format_partition "$usb_device"
    
    # Setup persistence
    setup_persistence "$usb_device"
    
    # Print completion information
    print_completion_info "$usb_device"
}

##############################################################################
# Script Entry Point
##############################################################################

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: sudo $0"
    echo ""
    echo "This script sets up persistence on a Kali Linux USB drive."
    echo "It will prompt you to select a USB device from the list displayed by lsblk."
    echo ""
    echo "Example:"
    echo "  sudo $0"
    echo ""
    echo "The script will:"
    echo "  1. Display all block devices using lsblk"
    echo "  2. Prompt you to enter the device name (sda, sdb, etc.)"
    echo "  3. Confirm your selection"
    echo "  4. Set up persistence automatically"
    exit 0
fi

# Run main function
main "$@"
