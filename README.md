Sure! Here's a more natural, human-friendly version of your project description, incorporating your goals and future plans:

---

# Podman AI Assistant

**Podman AI Assistant** is a command-line tool that helps you manage Podman containers using plain English. Just type what you want to do—like "list all containers"—and it turns that into a real Podman command for you. It's powered by a custom Ollama language model tuned specifically for Podman, making it both smart and practical.

Think of it as an open-source alternative to Docker's **Gordon**—but for Podman users. It’s designed to be simple to set up and safe to use, with built-in checks for potentially risky commands like `rm` or `stop`.

This is just the beginning—up next is **MCP server integration**, which will bring even more powerful capabilities to the assistant. Stay tuned, more to come!

## 🔧 Features

* Translates natural language into valid Podman CLI commands
  *Example: "list all containers" → `podman ps -a`*
* Asks for confirmation before running risky commands
* Uses a custom Ollama model (`podman-ai`) trained on Podman-specific tasks
* Configuration is clean and YAML-based
* Easy CLI access with the `podman-ai` alias



Here are some sample responses ;)

![Screenshot 2025-05-11 at 3 43 59 PM](https://github.com/user-attachments/assets/dd4ab821-5d9b-4b65-9e84-b0eb92372464)


![Screenshot 2025-05-11 at 3 47 15 PM](https://github.com/user-attachments/assets/90ece2fc-a9d6-4b0d-9383-1315de55db8d)






## 🚀 Quick Start

1. **Clone the repo**:

   ```bash
   git clone https://github.com/nalinrajendran/podman-agent.git
   cd podman-agent
   ```

2. **Install dependencies**:

   * [Ollama](https://ollama.com/download)
   * [Podman](https://podman.io/getting-started/installation)
   * Python packages:

     ```bash
     pip install -r requirements.txt
     ```
   * `yq` YAML CLI parser:

     ```bash
     # Ubuntu
     sudo apt-get install yq
     # Fedora
     sudo dnf install yq
     # macOS
     brew install yq
     ```

3. **Set up your custom model**:

   ```bash
   chmod +x bin/create_modelfile.sh
   bin/create_modelfile.sh
   ```

4. **Set up the CLI alias**:

   ```bash
   chmod +x bin/setup_podman_ai.sh
   bin/setup_podman_ai.sh
   source ~/.bashrc  # or ~/.zshrc
   ```

5. **Start using it!**

   ```bash
   podman-ai "list all containers"
   ```

For full setup instructions, see [docs/SETUP.md](docs/SETUP.md).

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for more info.

## 🤝 Contributing

Open to all kinds of contributions! Feel free to open issues or submit PRs on GitHub.

## 💬 Support

Check the [setup guide](docs/SETUP.md) or open an issue on [GitHub](https://github.com/nalinrajendran/podman-agent/issues).

---
