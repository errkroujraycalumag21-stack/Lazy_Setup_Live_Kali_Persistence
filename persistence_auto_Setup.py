import subprocess
import sys
import time

# ANSI Color Codes
CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

BANNER = f"""{CYAN}{BOLD}
  █  █ █▀▀█ █▀▀█   █▀▀█ █▀▀ █▀▀█ █▀▀ ▀█▀ █▀▀▀ █▀▀ █▀▀ █▀▀█ █▀▀ █▀▀
  █  █ ▀▀▀█ █▀▀▄   █▄▄█ █▀▀ █▄▄▀ ▀▀█  █  ▀▀▀█ ▀▀█ █▀▀ █  █ █   █▀▀
  ▀▄▄▀ █▄▄█ █▄▄█   █    ▀▀▀ ▀ ▀▀ ▀▀▀ ▀▀▀ ▀▀▀▀ ▀▀▀ ▀▀▀ ▀  ▀ ▀▀▀ ▀▀▀
{RESET}"""


def print_step(step_num, title):
    print(f"\n{CYAN}{BOLD}[+] STEP {step_num}:{RESET} {BOLD}{title}{RESET}")


def run(cmd):
    """Run a shell command and fail if it errors."""
    subprocess.run(cmd, shell=True, check=True)


def main():
    # Clear screen and display banner
    print("\033[H\033[J", end="")  # Clear screen escape sequence
    print(BANNER)
    print(
        f"{YELLOW}   === Live USB Persistence Setup Utility ===   {RESET}\n"
    )

    sdx = (
        input(f"{BOLD}Please enter chosen drive (e.g. sda, sdb): {RESET}")
        .strip()
        .lower()
    )

    if not sdx or "/" in sdx:
        print(f"{RED}[!] Invalid drive name provided.{RESET}")
        sys.exit(1)

    usb = f"/dev/{sdx}"

    # Confirmation prompt for safety
    print(
        f"\n{RED}{BOLD}WARNING:{RESET} Target device is {YELLOW}{usb}{RESET}. ALL DATA MAY BE OVERWRITTEN!"
    )
    confirm = input(
        f"{BOLD}Are you sure you want to proceed? (y/N): {RESET}"
    ).strip()
    if confirm.lower() != "y":
        print(f"{YELLOW}[*] Operation cancelled by user.{RESET}")
        sys.exit(0)

    # Step 1: Partitioning
    print_step(1, f"Partitioning device ({usb})...")
    fdisk_input = "p\nn\np\n\n\n\np\nw\n"
    run(f"echo -e '{fdisk_input}' | sudo fdisk {usb}")

    # Step 2: Create Filesystem
    print_step(2, f"Creating ext4 filesystem on {usb}3...")
    run(f"sudo mkfs.ext4 -L persistence {usb}3")

    # Step 3: Configure Persistence
    print_step(3, "Configuring persistence file...")
    run("sudo mkdir -pv /mnt/my_usb")
    run(f"sudo mount -v {usb}3 /mnt/my_usb")
    run('echo "/ union" | sudo tee /mnt/my_usb/persistence.conf')
    run("sudo umount -v /mnt/my_usb")

    print(f"\n{GREEN}{BOLD}[✓] Persistence creation completed successfully!{RESET}\n")

    # Step 4: Reboot Countdown
    print_step(4, "Rebooting system...")
    for i in range(5, 0, -1):
        print(
            f"\r{YELLOW}   --> Restarting in {i} second(s)...{RESET}",
            end="",
            flush=True,
        )
        time.sleep(1)

    print("\n")
    run("sudo reboot")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{RED}[!] Process interrupted by user.{RESET}")
        sys.exit(130)
    except subprocess.CalledProcessError as e:
        print(f"\n{RED}[!] Command failed with exit code {e.returncode}.{RESET}")
        sys.exit(e.returncode)
