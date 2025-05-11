#!/bin/bash

# Script to set up podman-ai alias for podman_ai.py

# Configuration
PYTHON_SCRIPT="src/podman_ai.py"
INSTALL_DIR="$HOME/.local/bin"
ALIAS_NAME="podman-ai"
ALIAS_COMMAND="python3 $INSTALL_DIR/podman_ai.py"

# Detect shell configuration file
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    SHELL_CONFIG="$HOME/.bash_profile"
fi

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: $PYTHON_SCRIPT not found in project directory."
    echo "Please ensure src/podman_ai.py is in the project directory."
    exit 1
fi

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy Python script to installation directory
cp "$PYTHON_SCRIPT" "$INSTALL_DIR/"
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy $PYTHON_SCRIPT to $INSTALL_DIR."
    exit 1
fi

# Set executable permissions
chmod +x "$INSTALL_DIR/podman_ai.py"

# Check if alias already exists in shell config
if grep -q "alias $ALIAS_NAME=" "$SHELL_CONFIG"; then
    echo "Alias $ALIAS_NAME already exists in $SHELL_CONFIG."
    echo "Updating existing alias..."
    sed -i.bak "/alias $ALIAS_NAME=/d" "$SHELL_CONFIG"
fi

# Add alias to shell config
echo "alias $ALIAS_NAME='$ALIAS_COMMAND'" >> "$SHELL_CONFIG"
if [ $? -ne 0 ]; then
    echo "Error: Failed to add alias to $SHELL_CONFIG."
    echo "You can manually add the following line to $SHELL_CONFIG:"
    echo "alias $ALIAS_NAME='$ALIAS_COMMAND'"
    exit 1
fi

# Source the shell config to apply changes (optional, for current session)
source "$SHELL_CONFIG" 2>/dev/null || echo "Please run 'source $SHELL_CONFIG' to apply changes in the current session."

# Verify setup
echo "Setup complete! You can now use '$ALIAS_NAME' to run podman_ai.py."
echo "Example: $ALIAS_NAME \"list all containers\""
echo "If the alias doesn't work, try restarting your terminal or running 'source $SHELL_CONFIG'."