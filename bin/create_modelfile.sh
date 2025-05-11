#!/bin/bash

# Script to create an Ollama Modelfile for podman-ai from modelfile_config.yaml

# Configuration

CONFIG_FILE="config/modelfile_config.yaml"
MODELFILE="Modelfile"
TEMP_DIR="./tmp_podman_ai"
YQ_BINARY="yq"  # Assumes yq is installed for YAML parsing

# Check if yq is installed
if ! command -v "$YQ_BINARY" &> /dev/null; then
    echo "Error: 'yq' is required to parse YAML. Install it using:"
    echo "  - Linux: sudo apt-get install yq (Ubuntu) or sudo dnf install yq (Fedora)"
    echo "  - macOS: brew install yq"
    echo "  - Or download from https://github.com/mikefarah/yq"
    exit 1
fi

# Check if modelfile_config.yaml exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found in current directory."
    echo "Please create $CONFIG_FILE with 'modelfile.base_model', 'modelfile.system_prompt', and 'modelfile.model_name' fields."
    exit 1
fi

# Extract settings from modelfile_config.yaml
BASE_MODEL=$("$YQ_BINARY" eval '.modelfile.base_model' "$CONFIG_FILE")
MODEL_NAME=$("$YQ_BINARY" eval '.modelfile.model_name' "$CONFIG_FILE")
SYSTEM_PROMPT=$("$YQ_BINARY" eval '.modelfile.system_prompt' "$CONFIG_FILE")
TEMPERATURE=$("$YQ_BINARY" eval '.modelfile.temperature' "$CONFIG_FILE")

# Validate extracted settings
if [ -z "$BASE_MODEL" ] || [ "$BASE_MODEL" = "null" ]; then
    echo "Error: 'modelfile.base_model' field not found or empty in $CONFIG_FILE."
    echo "Please specify a valid model (e.g., llama3.2)."
    exit 1
fi

if [ -z "$MODEL_NAME" ] || [ "$MODEL_NAME" = "null" ]; then
    echo "Error: 'modelfile.model_name' field not found or empty in $CONFIG_FILE."
    echo "Please specify a model name (e.g., podman-ai)."
    exit 1
fi

if [ -z "$SYSTEM_PROMPT" ] || [ "$SYSTEM_PROMPT" = "null" ]; then
    echo "Error: 'modelfile.system_prompt' field not found or empty in $CONFIG_FILE."
    echo "Please provide a valid system prompt."
    exit 1
fi

if [ -z "$TEMPERATURE" ] || [ "$TEMPERATURE" = "null" ]; then
    TEMPERATURE="0.3"  # Default temperature
    echo "Warning: 'modelfile.temperature' not specified. Using default: $TEMPERATURE."
fi

# Create temporary directory for Modelfile
mkdir -p "$TEMP_DIR"
MODELFILE_PATH="$TEMP_DIR/$MODELFILE"

# Generate Modelfile content
cat > "$MODELFILE_PATH" << EOF
# Modelfile for Podman AI Assistant
# Generated from $CONFIG_FILE

# Base model
FROM $BASE_MODEL

# System prompt for Podman command generation
SYSTEM """$SYSTEM_PROMPT"""

# Temperature for deterministic output
PARAMETER temperature $TEMPERATURE
EOF

# Check if Modelfile was created successfully
if [ ! -f "$MODELFILE_PATH" ]; then
    echo "Error: Failed to create $MODELFILE_PATH."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check if model already exists and prompt to overwrite
if ollama list | grep -q "$MODEL_NAME"; then
    read -p "Model '$MODEL_NAME' already exists. Overwrite? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "Operation cancelled."
        rm -rf "$TEMP_DIR"
        exit 0
    fi
    ollama rm "$MODEL_NAME"  # Remove existing model
    if [ $? -ne 0 ]; then
        echo "Error: Failed to remove existing model '$MODEL_NAME'."
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# Create the Ollama model
echo "Creating Ollama model '$MODEL_NAME' from $MODELFILE_PATH..."
ollama create "$MODEL_NAME" -f "$MODELFILE_PATH"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create Ollama model '$MODEL_NAME'."
    echo "Ensure Ollama is running ('ollama serve') and the base model '$BASE_MODEL' is installed ('ollama pull $BASE_MODEL')."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up temporary directory
rm -rf "$TEMP_DIR"

# Verify the model
echo "Verifying model creation..."
if ollama list | grep -q "$MODEL_NAME"; then
    echo "Success: Model '$MODEL_NAME' created successfully."
    echo "Update your ollama_config.yaml to use 'model: $MODEL_NAME' if not already set."
    echo "Test with: podman-ai \"list all containers\""
else
    echo "Warning: Model '$MODEL_NAME' not found in 'ollama list'."
    echo "Check Ollama logs or try re-running the script."
    exit 1
fi