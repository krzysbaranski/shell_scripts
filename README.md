# Shell Scripts

A collection of useful shell scripts.

## Scripts

### aur_update.sh
Updates AUR (Arch User Repository) packages.

### backup_github.sh
Backs up all repositories from a GitHub user account.

#### Features
- Lists all repositories for a specified GitHub user using the GitHub API
- Clones repositories that don't exist locally
- Pulls all remote branches for existing repositories
- Supports both authenticated (with GitHub token) and unauthenticated API access
- Handles pagination for users with many repositories
- **New**: Mirror clone mode for space-efficient backups (60-70% smaller)
- **New**: Download starred repositories with `--starred` flag
- **New**: Single-branch mode to clone only the default branch with `--single-branch` flag

#### Requirements
- `jq` - Command-line JSON processor
  - Ubuntu/Debian: `sudo apt-get install jq`
  - Arch Linux: `sudo pacman -S jq`
  - macOS: `brew install jq`

#### GitHub API Token (Optional but Recommended)

For higher rate limits and access to private repositories, generate a GitHub API token:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Backup Script")
4. Select scopes:
   - `repo` (for full access including private repos)
   - or `public_repo` (for public repositories only)
5. Click "Generate token" and copy the token
6. Set the token as an environment variable:
   ```bash
   export GITHUB_TOKEN="your_token_here"
   ```
   Or add it to your `~/.bashrc` or `~/.zshrc` for persistence:
   ```bash
   echo 'export GITHUB_TOKEN="your_token_here"' >> ~/.bashrc
   source ~/.bashrc
   ```

#### Usage

```bash
./backup_github.sh [OPTIONS] [backup_directory] [github_username]
```

**Options:**
- `--mirror` - Use mirror clones (bare repositories) instead of regular clones
  - More space-efficient (60-70% smaller)
  - Includes all branches, tags, and pull request refs
  - No working directory (stores only git data)
  - Perfect for backups and archives
- `--starred` - Download all repositories starred by the user instead of their own repos
  - Starred repos are organized in `owner/repo` subdirectories to avoid name collisions
  - Can be combined with `--mirror` for space-efficient backups of starred repos
- `--single-branch` - Clone only the default branch (faster and uses less disk space)
  - Skips fetching all remote branches during clone and updates
  - Useful when you only need the latest state of the main/master branch

**Examples:**

```bash
# Backup krzysbaranski's repos to ~/github_backup (default)
./backup_github.sh

# Backup to a specific directory
./backup_github.sh ~/backups/github krzysbaranski

# Use mirror clones for space-efficient backups
./backup_github.sh --mirror ~/backups/github krzysbaranski

# Download all starred repositories
./backup_github.sh --starred ~/backups/github krzysbaranski

# Starred repositories with mirror clones
./backup_github.sh --starred --mirror ~/backups/github krzysbaranski

# Clone only the default branch (faster, less disk space)
./backup_github.sh --single-branch ~/backups/github krzysbaranski

# Single branch with starred repositories
./backup_github.sh --single-branch --starred ~/backups/github krzysbaranski

# With authentication token
GITHUB_TOKEN=ghp_xxxxxxxxxxxx ./backup_github.sh ~/backups/github krzysbaranski

# Mirror clone with authentication
GITHUB_TOKEN=ghp_xxxxxxxxxxxx ./backup_github.sh --mirror ~/backups/github krzysbaranski

# Or set the token first
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx
./backup_github.sh --mirror ~/backups/github krzysbaranski
```

**Default values:**
- Backup directory: `$HOME/github_backup`
- GitHub username: `krzysbaranski`

#### What it does

**Regular mode (default):**
1. Fetches a list of all repositories for the specified user
2. For each repository:
   - If the repository doesn't exist locally: clones it and creates local tracking branches for all remote branches
   - If the repository exists locally: fetches all remote branches and updates them
3. Returns to the default branch after processing each repository

**Mirror mode (`--mirror` flag):**
1. Fetches a list of all repositories for the specified user
2. For each repository:
   - If the mirror doesn't exist locally: creates a mirror clone (bare repository with `.git` suffix)
   - If the mirror exists locally: updates all refs (branches, tags, pull requests)
3. Mirror clones are bare repositories (no working directory) and are 60-70% smaller than regular clones
4. Mirror clones include all repository refs including pull request refs that regular clones don't have

**Starred mode (`--starred` flag):**
1. Fetches a list of all repositories starred by the specified user
2. Repositories are organized in `owner/repo` subdirectories to avoid name collisions
3. Each repository is cloned or updated using the same logic as regular or mirror mode
4. Can be combined with `--mirror` for space-efficient backups

**Single-branch mode (`--single-branch` flag):**
1. Clones only the default branch of each repository (no extra branches are fetched)
2. When updating an existing repository, only the currently checked-out branch is pulled
3. Faster and uses less disk space — ideal when full branch history is not needed
4. Can be combined with `--starred` to clone only the default branch of starred repos

#### Rate Limits

- **Without token**: 60 requests per hour (sufficient for ~6000 repositories)
- **With token**: 5000 requests per hour

## License

MIT
