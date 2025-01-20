#!/bin/bash

# Check if setup is haven't sudo permissions
if [ "$EUID" -ne 0 ]; then
	echo "This script must be run as root. Please use: sudo $0"
	exit 1
fi

GIT_URL="https://github.com/UCTRONICS/U6143_ssd1306.git"
BASE_DIR="/home/pi/U6143_ssd1306"
C_DIR="$BASE_DIR/C"
PYTHON_DIR="$BASE_DIR/python"
RC_LOCAL="/etc/rc.local"
RC_CMD="cd $C_DIR && sudo make clean && sudo make && sudo ./display &"

echo "Starting U6143_ssd1306 setup..."

# Enable I2C interface
echo "Enabling I2C interface..."
sudo raspi-config nonint do_i2c 0 || {
	echo "Failed to enable I2C interface. Exiting."
	exit 1
}

# Clone repository
if [ ! -d "$BASE_DIR" ]; then
	echo "Cloning U6143_ssd1306 repository..."
	git clone $GIT_URL "$BASE_DIR" || {
		echo "Failed to clone repository. Exiting."
		exit 1
	}
else
	echo "Repository already exists. Skipping clone."
fi

# Compile C project
echo "Compiling the C project..."
cd "$C_DIR" || {
	echo "Failed to navigate to $C_DIR. Exiting."
	exit 1
}
sudo make clean && sudo make || {
	echo "Failed to compile the project. Exiting."
	exit 1
}

# Configure automatic start
if [ ! -f "$RC_LOCAL" ]; then
	echo "File $RC_LOCAL does not exist. Creating a new one..."
	
	# Create a new rc.local file with necessary structure
	sudo bash -c "cat <<EOF > $RC_LOCAL
#!/bin/bash
# rc.local
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will exit with 0 on success or any other value on error.
# In order to enable or disable this script just change the execution bits.
# By default this script does nothing.

$RC_CMD

exit 0
EOF"
	# Set executable permissions
	sudo chmod +x "$RC_LOCAL" || {
		echo "Failed to set executable permissions for $RC_LOCAL. Exiting."
		exit 1
	}
	echo "Created and configured $RC_LOCAL."
else
	if ! grep -qF "$RC_CMD" "$RC_LOCAL"; then
		echo "Configuring automatic start in $RC_LOCAL..."
		sudo sed -i "/^exit 0/i $RC_CMD" "$RC_LOCAL" || {
			echo "Failed to update $RC_LOCAL. Exiting."
			exit 1
		}
		echo "Automatic start configured."
	else
		echo "Automatic start already configured in $RC_LOCAL. Skipping."
	fi
fi

# Test the display

# echo "Running initial display test..."
# sudo ./display || {
# 	echo "Failed to run the display test. Check connections and setup."
# }

echo "Running initial display test for 10 seconds..."
sudo ./display &
DISPLAY_PID=$!  # Capture the PID of the background process
sleep 10        # Wait for 10 seconds
kill -INT $DISPLAY_PID || {  # Send Ctrl+C (SIGINT) to stop the display
  echo "Failed to stop the display process. Please check manually."
}


echo "Setup completed. Please reboot the system for changes to take effect."
