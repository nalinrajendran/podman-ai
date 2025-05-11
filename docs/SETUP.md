# Podman AI Assistant Setup Instructions

This guide provides step-by-step instructions for setting up the Podman AI Assistant, a tool that translates natural language queries into Podman commands using a custom Ollama model. The setup is designed to be straightforward, with clear steps for installing dependencies, configuring the system, and testing the assistant.

## Project Structure

The project is organized as follows:
```
podman-agent/
├── bin/                    # Setup scripts
│   ├── create_modelfile.sh
│   └── setup_podman_ai.sh
├── config/                 # Configuration files
│   ├── ollama_config.yaml
│   └── modelfile_config.yaml
├── src/                    # Source code
│   └── podman_ai.py
├── docs/                   # Documentation
│   └── SETUP.md
├── requirements.txt        # Python dependencies
├── LICENSE                 # License file
└── README.md               # Project overview
```

## Prerequisites

Ensure the following are installed before starting:

1. **Ollama**:
   - Download and install: [Ollama Downloads](https://ollama.com/download).
   - Start the server: `ollama serve`.
   - Install the base model (e.g., `llama3.2`): `ollama pull llama3.2`.
   - Verify: `curl http://localhost:11434/api/tags`.

2. **Podman**:
   - Install: [Podman Installation](https://podman.io/getting-started/installation).
   - Verify: `podman --version`.

3. **Python 3**:
   - Install Python 3.6 or higher.
   - Verify: `python3 --version`.

4. **yq** (YAML parser):
   - Install:
     - **Ubuntu**: `sudo apt-get install yq`
     - **Fedora**: `sudo dnf install yq`
     - **macOS**: `brew install yq`
     - **Manual**: [yq GitHub](https://github.com/mikefarah/yq).
   - Verify: `yq --version`.

5. **Shell Environment**:
   - Bash, Zsh, or similar.
   - Ensure `~/.local/bin` is in your `PATH`:
     ```bash
     echo $PATH
     ```
     If not, add it:
     ```bash
     echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
     source ~/.bashrc
     ```

## Setup Steps

### Step 1: Clone the Repository


```bash
cd podman-agent
```

### Step 2: Install Python Dependencies

Install the required Python libraries:

```bash
pip install -r requirements.txt
```

Verify:
```bash
pip show requests pyyaml
```

### Step 3: Configure the Custom Ollama Model

1. **Verify `modelfile_config.yaml`**:
   Ensure `config/modelfile_config.yaml` is set up correctly:
   ```yaml
   modelfile:
     base_model: "llama3.2"
     system_prompt: |
       You are a CLI assistant for Podman, a container management tool. Your task is to translate user requests into a single, valid Podman command. Follow these rules:

       - Return ONLY the Podman command, starting with 'podman'.
       - Do NOT include code (e.g., Python, bash), explanations, comments, or extra text.
       - Do NOT wrap the command in backticks, quotes, or any formatting.
       - If the request is ambiguous or unclear, return 'podman ps -a'.
       - Ensure the command is executable and matches Podman CLI syntax.

       Example: Request: stop the my-app container Response: podman stop my-app
     model_name: "podman-ai"
     temperature: 0.3
   ```

2. **Make the Modelfile Script Executable**:
   ```bash
   chmod +x bin/create_modelfile.sh
   ```

3. **Create the Model**:
   ```bash
   bin/create_modelfile.sh
   ```

   **Expected Output**:
   ```
   Creating Ollama model 'podman-ai' from ./tmp_podman_ai/Modelfile...
   Success: Model 'podman-ai' created successfully.
   Update your config/ollama_config.yaml to use 'model: podman-ai' if not already set.
   Test with: podman-ai "list all containers"
   ```

   If prompted to overwrite an existing model, confirm with `y`.

4. **Verify the Model**:
   ```bash
   ollama list
   ```
   Ensure `podman-ai` is listed.

### Step 4: Configure Ollama Settings

1. **Verify `ollama_config.yaml`**:
   Ensure `config/ollama_config.yaml` uses the `podman-ai` model:
   ```yaml
   ollama:
     url: "http://localhost:11434/api/generate"
     model: "podman-ai"
   podman_ai:
     risky_commands:
       - "rm"
       - "rmi"
       - "stop"
       - "kill"
       - "prune"
       - "uninstall"
   ```

2. **Customize (Optional)**:
   - Change `url` for a different Ollama server.
   - Adjust `risky_commands` to modify confirmation prompts.

### Step 5: Set Up the `podman-ai` Alias

1. **Make the Alias Script Executable**:
   ```bash
   chmod +x bin/setup_podman_ai.sh
   ```

2. **Run the Script**:
   ```bash
   bin/setup_podman_ai.sh
   ```

   **Expected Output**:
   ```
   Setup complete! You can now use 'podman-ai' to run podman_ai.py.
   Example: podman-ai "list all containers"
   If the alias doesn't work, try restarting your terminal or running 'source ~/.bashrc'.
   ```

3. **Refresh Shell**:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

4. **Verify**:
   ```bash
   which podman-ai
   ```
   Should show `~/.local/bin/podman_ai.py`.

### Step 6: Test the Assistant

1. **Safe Command**:
   ```bash
   podman-ai "list all containers"
   ```

   **Expected Output**:
   ```
   🔍 User query: list all containers
   🤖 Ollama generated: podman ps -a
   ✅ Command output:
   CONTAINER ID  IMAGE                           COMMAND               CREATED        STATUS                    PORTS                   NAMES
   abc123        docker.io/library/nginx:latest  nginx -g daemon o...  2 days ago     Exited (0) 2 days ago                             my-app
   ```

2. **Risky Command**:
   ```bash
   podman-ai "stop container my-app"
   ```

   **Expected Output**:
   ```
   🔍 User query: stop container my-app
   🤖 Ollama generated: podman stop my-app
   ⚠️ Risky command detected: podman stop my-app
   Do you want to proceed? (yes/no): yes
   ✅ Command output:
   my-app
   ```

3. **Ambiguous Query**:
   ```bash
   podman-ai "do something"
   ```

   **Expected Output**:
   ```
   🔍 User query: do something
   🤖 Ollama generated: podman ps -a
   ✅ Command output:
   ...
   ```

## Troubleshooting

### Ollama Issues
- **Server Not Running**: Start with `ollama serve`.
- **Model Not Found**: Install with `ollama pull llama3.2`.
- **Incorrect Commands**: Verify `config/ollama_config.yaml` uses `model: "podman-ai"`.

### Podman Issues
- **Command Not Found**: Install Podman.
- **Permissions**: Test manually: `podman ps -a`.

### Python Issues
- **Missing Libraries**: Re-run `pip install -r requirements.txt`.
- **Config Errors**: Ensure `config/ollama_config.yaml` is valid YAML.

### Alias Issues
- **Not Working**: Run `source ~/.bashrc` or restart terminal.
- **Path Issue**: Verify `~/.local/bin` in `PATH`.

### Modelfile Issues
- **Creation Fails**: Check `yq` installation, `config/modelfile_config.yaml` validity.
- **Model Missing**: Re-run `bin/create_modelfile.sh`.

## Customization

- **Change Ollama Server**:
  Edit `config/ollama_config.yaml`:
  ```yaml
  ollama:
    url: "http://192.168.1.100:11434/api/generate"
  ```

- **Modify Risky Commands**:
  Update `config/ollama_config.yaml`:
  ```yaml
  podman_ai:
    risky_commands:
      - "rm"
      - "rmi"
  ```

- **Change Base Model**:
  Edit `config/modelfile_config.yaml`:
  ```yaml
  modelfile:
    base_model: "mistral"
  ```

## Contributing

Contributions are welcome! Please:
1. Fork the repository.
2. Create a feature branch: `git checkout -b feature-name`.
3. Commit changes: `git commit -m "Add feature"`.
4. Push: `git push origin feature-name`.
5. Open a pull request.

## License

This project is licensed under the MIT License. See [LICENSE](../LICENSE).

## Support

For issues, consult this guide or open an issue on [GitHub](https://github.com/nalinrajendran/podman-agent/issues).