#!/bin/bash 
# Before usage move me to another direcvtory.
# The goal of this script is to use a single Burp Pro Licence on all exegol instance.

# Part 1: Preparation and copying resources

# Get the username and home directory
# Check if running with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Get the original user who ran sudo
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_NAME")

echo "Detected user: $USER_NAME"
echo "User home directory: $USER_HOME"


USER_JAVA="$USER_HOME/.java"
USER_BurpSuiter="$USER_HOME/.BurpSuite"
BurpsuitePro="/opt/BurpSuitePro"

# Define target directory
TARGET_DIR="$USER_HOME/.exegol/my-resources/"
if [ ! -d "$USER_HOME/.java" ]; then
    echo "exegol environment not found, are you sure it is installed?"
    echo "edit TARGET_DIR with the valid path of my-resources directory."
    exit 1
fi

check_success() {
    if [ $? -ne 0 ]; then
        echo "Error occurred in command: $1. Exiting."
        exit 1
    fi
}


# Check if the directory .java exists or if a specific path is set in JAVA_HOME
if [ -d "$USER_JAVA" ]; then
    JAVA_DEST="$TARGET_DIR"".java"
    if [ -d $JAVA_DEST ]; then
        echo ".java directory already copied"
    else 
        cp -r "$USER_JAVA" "$TARGET_DIR"
        check_success "cp -r $USER_JAVA $TARGET_DIR"
        echo ".java directory copied to $TARGET_DIR"
        chown $USER_NAME $JAVA_DEST
        check_success "chown $USER_NAME $JAVA_DEST"
    fi
fi

# Check if the directory .BurpSuite exists or if a specific path is set in BURPSUITE_HOME
if [ -d "$USER_BurpSuiter" ]; then
    
    BURP_DIR="$TARGET_DIR/.BurpSuite"
    if [ -d $BURP_DIR ]; then
        echo ".BurpSuite directory already copied"
    else 
        cp -r "$USER_BurpSuiter" "$TARGET_DIR"
        check_success "cp -r $USER_BurpSuiter $TARGET_DIR"
        echo ".BurpSuite directory copied to $TARGET_DIR"
        chown $USER_NAME $BURP_DIR
        check_success "chown $USER_NAME $BURP_DIR"
    fi
fi

# Check if /opt/BurpSuitePro exists or if a specific path is set in BURPSUITEPRO_HOME
if [ -d "$BurpsuitePro" ]; then
    BURPPRO_DIR="$TARGET_DIR/BurpSuitePro"
    if [ -d $BURPPRO_DIR ]; then
        echo "BurpSuitePro directory already copied"
    else
        cp -r "$BurpsuitePro" "$TARGET_DIR"
        check_success "cp -r $BurpsuitePro $TARGET_DIR"
        echo "BurpSuitePro directory copied to $TARGET_DIR"
        chown $USER_NAME $BURPPRO_DIR
        check_success chown $USER_NAME $BURPPRO_DIR
    fi
fi

# Part 2: Generate a follow-up script for Docker setup

# Define the follow-up script file
FOLLOW_UP_SCRIPT="$USER_HOME/setup_in_docker.sh"
cat << EOF > "$FOLLOW_UP_SCRIPT"
#!/bin/bash

# Check if running inside Docker
if [ "\$(ps -p 1 -o comm=)" != "systemd" ] && \
   [ "\$(hostname | grep -cE '^[a-f0-9]{12}$')" -eq 1 ]; then
    echo "Your environment will be modified."
else
    echo "Not running inside Docker. Exiting."
    exit 1
fi
if ! grep -q docker /proc/1/cgroup; then
    echo "Not running inside Docker. Exiting."
    exit 1
fi

# Create a new user with the detected username
USER_NAME="$USER_NAME"
useradd -m -G root "\$USER_NAME"

# Create symbolic links for resources in /opt/my-resources
ln -s /opt/my-resources/.java "/home/\$USER_NAME/.java"
ln -s /opt/my-resources/.BurpSuite "/home/\$USER_NAME/.BurpSuite"
ln -s /opt/my-resources/BurpSuitePro "/home/\$USER_NAME/BurpSuitePro"

# Set ownership of the resources to the new user
chown -R "\$USER_NAME" /opt/my-resources/.java /opt/my-resources/.BurpSuite /opt/my-resources/BurpSuitePro

# Create a persistent alias for BurpSuitePro
shell_name=$(env | grep EXEGOL_START_SHELL | cut -d "=" -f2)

if [ -z "$shell_name" ]; then
    echo "Error - the EXEGOL_START_SHELL global environment is not set"
    echo "Try PYENV_SHELL var instead..."
    shell_name=$(env | grep PYENV_SHELL | cut -d "=" -f2)
    if [ -z "$shell_name" ]; then
        echo "Error - the PYENV_SHELL global environment is not set"
        echo "Abort"
        exit
    fi
fi

rc_file="$HOME/."$shell_name"rc"

echo "alias b='sudo -u $USER_NAME /home/$USER_NAME/BurpSuitePro/BurpSuitePro'" >> "$rc_file"
echo "alias myburp='sudo -u $USER_NAME /home/$USER_NAME/BurpSuitePro/BurpSuitePro'" >> "$rc_file"

echo "Alias b and myburp pushed in $rc_file"
EOF

# Make the follow-up script executable
chmod +x "$FOLLOW_UP_SCRIPT"
echo "Follow-up Docker setup script created at $FOLLOW_UP_SCRIPT"
echo "execute it in your exegol container :)"
