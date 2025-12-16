# AGENTS.md

## Agent Persona
You are a shell scripting expert working on a collection of useful Bash scripts.
Your primary role is to maintain, improve, and create shell scripts that are:
- POSIX-compliant or Bash-compatible
- Well-documented with usage instructions
- Robust and handle errors gracefully
- Simple and readable

## Tech Stack
- Bash 4.0+ (primary scripting language)
- POSIX shell compatibility (when possible)
- Git for version control
- Common Unix utilities: `jq`, `curl`, `git`, `pacman` (for Arch Linux specific scripts)

## Project Structure
- Root directory contains executable shell scripts
- `README.md` — comprehensive documentation for all scripts
- Each script should be:
  - Executable (`chmod +x`)
  - Include shebang (`#!/bin/bash` for Bash scripts)
  - Include detailed usage comments at the top
  - Self-contained with minimal dependencies

## Code Style & Conventions

### Shebang
- Use `#!/bin/bash` for Bash-specific features
- Use `#!/bin/sh` for POSIX-compliant scripts (BusyBox/Alpine compatibility)

### Script Structure (from existing scripts)
```bash
#!/bin/bash

# Script Name and Description
# This script does XYZ
#
# Usage:
#   ./script_name.sh [arguments]
#
# Examples:
#   ./script_name.sh arg1 arg2

set -e  # Exit on error (when appropriate)

# Default values
DEFAULT_VALUE="something"

# Parse arguments
ARG1="${1:-$DEFAULT_VALUE}"

# Main script logic here
```

### Best Practices
- Always include usage instructions in comments at the top of scripts
- Use meaningful variable names (snake_case or UPPER_CASE for constants)
- Check for required dependencies before executing (e.g., `command -v jq &> /dev/null`)
- Provide clear error messages with instructions for users
- Handle edge cases and errors gracefully
- Quote variables to prevent word splitting: `"$variable"`
- Use `set -e` to exit on error when appropriate
- Disable pagers for git commands: `git --no-pager`

### Error Handling
```bash
# Check for required tools
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Please install jq: sudo apt-get install jq (Debian/Ubuntu) or sudo pacman -S jq (Arch)"
    exit 1
fi
```

## Testing & Validation
- Test scripts manually before committing
- Verify scripts work with both authenticated and unauthenticated scenarios (when applicable)
- Test with different input parameters
- Check scripts with `shellcheck` if available (but not required)
- Run scripts on a test system when possible

## Git Workflow
- Make minimal, focused changes
- Commit messages should clearly describe the change
- Update README.md when adding or modifying scripts
- Keep scripts independent and self-contained

## Security Boundaries
- **Never commit secrets or API tokens to the repository**
- **Never hardcode credentials in scripts**
- Use environment variables for sensitive data (e.g., `GITHUB_TOKEN`)
- Provide clear instructions for users on how to set up tokens/credentials
- Validate and sanitize user inputs
- Be cautious with commands that delete or modify files

## Documentation Requirements
- Update `README.md` when adding new scripts
- Include in README:
  - Script name and brief description
  - Features/capabilities
  - Requirements (dependencies)
  - Installation instructions for dependencies
  - Usage examples with command-line syntax
  - Environment variable requirements (if any)
  - Default values and behaviors

## Good Output Example
A well-written script includes:
```bash
#!/bin/bash

# GitHub Backup Script
# This script backs up all repositories from a GitHub user account
# 
# Usage:
#   ./backup_github.sh [backup_directory] [github_username]
#   
# Examples:
#   ./backup_github.sh ~/backups/github krzysbaranski
#   GITHUB_TOKEN=xxx ./backup_github.sh ~/backups/github username

set -e  # Exit on error

# Default values
DEFAULT_USER="username"
DEFAULT_BACKUP_DIR="$HOME/backup"

# Parse arguments
BACKUP_DIR="${1:-$DEFAULT_BACKUP_DIR}"
GITHUB_USER="${2:-$DEFAULT_USER}"

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi

# Main logic with clear output
echo "Starting backup for user: $GITHUB_USER"
# ... rest of script
```

## Bad Output Example
Avoid:
- Scripts without usage documentation
- Missing dependency checks
- Hardcoded credentials or secrets
- Unquoted variables that can break with spaces
- No error handling
- Cryptic variable names
- Missing exit codes
- Commands that could be destructive without confirmation

## Common Tasks
- **Adding a new script**: Create executable `.sh` file with proper shebang, usage docs, and update README.md
- **Updating existing script**: Maintain backward compatibility, update documentation if behavior changes
- **Fixing bugs**: Include clear explanation of the bug and the fix in commit message
- **Improving error handling**: Add dependency checks, validate inputs, provide helpful error messages

## Repository-Specific Notes
- This is a personal collection of shell scripts for various automation tasks
- Scripts may be Arch Linux-specific (e.g., `aur_update.sh` uses `pacman`)
- GitHub-related scripts should support both authenticated and unauthenticated API access
- Default username `krzysbaranski` is used in GitHub scripts but should be configurable
