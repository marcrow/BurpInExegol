# BurpInExegol
A simple script to share a same instance of Burp beetween multiple exegol instance.

## Summary
This script facilitates the sharing of a single Burp Pro license across multiple Exegol instances. It accomplishes this by copying necessary Burp Suite and Java directories to a common resource directory and generating a follow-up script for setting up symbolic links inside the Exegol container.

## Prerequisites
- Ensure you have **sudo** privileges before executing the script.
- Make sure Exegol is properly installed.
- The script should be placed in a separate directory before use.

## How It Works
### **Part 1: Copying Resources**
1. The script checks if it is run with **sudo**. If not, it exits.
2. It detects the username and home directory of the original user.
3. It verifies the presence of Exegol's `my-resources` directory.
4. It copies the following directories if they exist:
   - `.java` → `$HOME/.exegol/my-resources/.java`
   - `.BurpSuite` → `$HOME/.exegol/my-resources/.BurpSuite`
   - `BurpSuitePro` (default: `/opt/BurpSuitePro`) → `$HOME/.exegol/my-resources/BurpSuitePro`
5. The script assigns the correct permissions to the copied resources.

### **Part 2: Generating a Follow-Up Script**
1. The script generates a new script: `setup_in_docker.sh` inside $HOME/.exegol/my-resources/.
2. This follow-up script should be executed inside an Exegol container via the command /opt/my-resources/setup_in_docker.sh.
3. It checks if the script is running inside Docker before proceeding.
4. It creates a new user inside the container with the same username.
5. It sets up symbolic links to the copied resources.
6. It ensures correct permissions are applied.
7. It adds an alias (`b`) to launch BurpSuitePro inside the container.

## Usage
### Step 1: Run the script on the host machine
```bash
sudo ./BurpInExegol.sh
```
This will copy the required files and create the follow-up script.

### Step 2: Execute the follow-up script inside the Exegol container
```bash
/opt/my-resources/setup_in_docker.sh
```
This will configure the environment inside the container and allow BurpSuitePro to run.

## Troubleshooting
- **"Please run this script with sudo."** → Ensure you execute it with `sudo`.
- **"Exegol environment not found."** → Verify that Exegol is installed and adjust `TARGET_DIR` if necessary.
- **Files not copied correctly.** → Ensure that the original `.java`, `.BurpSuite`, and `BurpSuitePro` directories exist.

## Notes
- The script is designed to be idempotent. If resources are already copied, it will skip them.
- The alias `b` and `myburp` allows launching BurpSuitePro conveniently inside the container.
