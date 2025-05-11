import requests
import subprocess
import json
import sys
import yaml

# Load configuration from YAML file
CONFIG_FILE = "config/ollama_config.yaml"
try:
    with open(CONFIG_FILE, "r") as f:
        config = yaml.safe_load(f)
    OLLAMA_URL = config["ollama"]["url"]
    MODEL = config["ollama"]["model"]
    RISKY_COMMANDS = config["podman_ai"]["risky_commands"]
except FileNotFoundError:
    print(f"Warning: {CONFIG_FILE} not found. Using default settings.")
    OLLAMA_URL = "http://localhost:11434/api/generate"
    MODEL = "llama3.2"
    RISKY_COMMANDS = ["rm", "rmi", "stop", "kill", "prune", "uninstall"]
except KeyError as e:
    print(f"Error: Invalid {CONFIG_FILE} format. Missing key: {e}")
    sys.exit(1)

def run_podman_help():
    """Get the output of 'podman help'."""
    try:
        result = subprocess.run(["podman", "help"], capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        return f"Could not retrieve podman help: {e}"

def build_prompt(user_query, podman_help_text=None):
    """Builds a context-rich prompt for Ollama."""
    example = (
        "### Example:\n"
        "Request: Run an Alpine container interactively with a terminal.\n"
        "Response: podman run -it alpine /bin/sh\n\n"
    )
    instructions = (
        "You are a CLI assistant. You convert plain language instructions into Podman commands.\n"
        "You must return ONLY one single valid Podman command. No explanations.\n"
        "If unsure, refer to the podman CLI help below.\n"
    )

    prompt = example + instructions
    if podman_help_text:
        prompt += f"\n### podman help:\n{podman_help_text[:2000]}..."  # Limit context if needed
    prompt += f"\n\n### Request: {user_query}"

    return prompt

def query_ollama(user_query, help_context=None):
    """Query the Ollama model, optionally with podman help context."""
    prompt = build_prompt(user_query, help_context)
    payload = {
        "model": MODEL,
        "prompt": prompt,
        "stream": False
    }
    try:
        response = requests.post(OLLAMA_URL, json=payload)
        response.raise_for_status()
        return json.loads(response.text).get("response", "").strip()
    except requests.RequestException as e:
        return f"Error querying Ollama: {e}"

def is_valid_podman_command(command):
    return command.startswith("podman") and "\n" not in command and len(command.split()) > 1

def confirm_execution_if_needed(command):
    if any(word in command for word in RISKY_COMMANDS):
        print(f"⚠️ Risky command detected: {command}")
        confirm = input("Do you want to proceed? (yes/no): ").strip().lower()
        if confirm != "yes":
            print("Operation cancelled.")
            sys.exit(0)

def execute_podman_command(command):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return result.stdout if result.returncode == 0 else f"❌ Error: {result.stderr}"
    except subprocess.SubprocessError as e:
        return f"Error executing command: {e}"

def main():
    if len(sys.argv) < 2:
        print("Usage: python podman_ai.py <query>")
        sys.exit(1)

    user_query = " ".join(sys.argv[1:])
    print(f"🔍 User query: {user_query}")

    # First attempt without help context
    command = query_ollama(user_query)

    if not is_valid_podman_command(command):
        print("⚠️ First attempt failed. Trying again with podman help context...")
        help_text = run_podman_help()
        command = query_ollama(user_query, help_text)

    if not is_valid_podman_command(command):
        print("❌ Failed to generate a valid Podman command after retry.")
        print("Consider reviewing your query or checking Podman documentation.")
        sys.exit(1)

    print(f"🤖 Ollama generated: {command}")
    confirm_execution_if_needed(command)
    output = execute_podman_command(command)
    print(f"✅ Command output:\n{output}")

if __name__ == "__main__":
    main()