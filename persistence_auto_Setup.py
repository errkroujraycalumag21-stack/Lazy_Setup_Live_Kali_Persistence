import subprocess
import time

def run(cmd):
    # Run a shell command and fail if it errors
    subprocess.run(cmd, shell=True, check=True)

sdx = input("please enter chosen drive ex.sda,sdb,etc : ").strip()  # e.g. "sdb"
usb = f"/dev/{sdx}"

# BE CAREFUL: this will modify the disk/partition table
# We'll feed commands into fdisk (same concept as a heredoc).
fdisk_input = "p\nn\np\n\n\n\np\nw\n"
run(f"echo -e '{fdisk_input}' | sudo fdisk {usb}")

# Create filesystem on partition 3
run(f"sudo mkfs.ext4 -L persistence {usb}3")

# Configure persistence
run("sudo mkdir -pv /mnt/my_usb")
run(f"sudo mount -v {usb}3 /mnt/my_usb")
run('echo "/ union" | sudo tee /mnt/my_usb/persistence.conf')
run("sudo umount -v /mnt/my_usb")

# Countdown + reboot
for i in range(5, 0, -1):
    print(f"restarting in {i} second")
    time.sleep(1)

run("sudo reboot")
