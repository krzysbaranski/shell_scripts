#!/bin/sh

# GitHub Backup Script
# This script backs up all repositories from a GitHub user account
# 
# GitHub API Token Generation Instructions:
# 1. Go to https://github.com/settings/tokens
# 2. Click "Generate new token" -> "Generate new token (classic)"
# 3. Give it a descriptive name (e.g., "Backup Script")
# 4. Select scopes: "repo" (for private repos) or "public_repo" (for public only)
# 5. Click "Generate token" and copy the token
# 6. Set the token as an environment variable:
#    export GITHUB_TOKEN="your_token_here"
#    Or add it to your ~/.bashrc or ~/.zshrc for persistence
#
# Usage:
#   ./backup_github.sh [OPTIONS] [backup_directory] [github_username]
#   
# Options:
#   --mirror    Use mirror clones (bare repositories, more space-efficient)
#               Mirror clones include all branches, tags, and pull request refs
#   
# Examples:
#   ./backup_github.sh ~/backups/github krzysbaranski
#   ./backup_github.sh --mirror ~/backups/github krzysbaranski
#   GITHUB_TOKEN=xxx ./backup_github.sh --mirror ~/backups/github krzysbaranski

set -e  # Exit on error

# Default values
DEFAULT_USER="krzysbaranski"
DEFAULT_BACKUP_DIR="$HOME/github_backup"
USE_MIRROR=0

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --mirror)
            USE_MIRROR=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

BACKUP_DIR="${1:-$DEFAULT_BACKUP_DIR}"
GITHUB_USER="${2:-$DEFAULT_USER}"

# Check if jq is installed (for JSON parsing)
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed."
    echo "Please install jq: sudo apt-get install jq (Debian/Ubuntu) or sudo pacman -S jq (Arch)"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

echo "==================================="
echo "GitHub Backup Script"
echo "==================================="
echo "User: $GITHUB_USER"
echo "Backup directory: $BACKUP_DIR"
if [ $USE_MIRROR -eq 1 ]; then
    echo "Mode: Mirror clone (bare repository)"
else
    echo "Mode: Regular clone (with working directory)"
fi
echo "-----------------------------------"

# Prepare API headers
if [ -n "$GITHUB_TOKEN" ]; then
    echo "Using authenticated API (with token)"
    AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
else
    echo "Using unauthenticated API (rate limit: 60 requests/hour)"
    echo "Set GITHUB_TOKEN environment variable for higher rate limits and private repo access"
    AUTH_HEADER=""
fi

echo "-----------------------------------"

# Function to get all repositories for a user
get_repositories() {
    local user=$1
    local page=1
    local per_page=100
    
    while true; do
        local url="https://api.github.com/users/$user/repos?page=$page&per_page=$per_page&type=all"
        
        if [ -n "$AUTH_HEADER" ]; then
            response=$(curl -s -H "$AUTH_HEADER" "$url")
        else
            response=$(curl -s "$url")
        fi
        
        # Check for API errors
        if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
            error_msg=$(echo "$response" | jq -r '.message')
            echo "Error from GitHub API: $error_msg"
            exit 1
        fi
        
        # Parse repository names and clone URLs
        page_repos=$(echo "$response" | jq -r '.[] | "\(.name)|\(.clone_url)"')
        
        # Break if no more repositories
        if [ -z "$page_repos" ]; then
            break
        fi
        
        # Output page repositories
        printf '%s\n' "$page_repos"
        page=$((page + 1))
    done
}

# Helper function to get default branch
get_default_branch() {
    local default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
    if [ -n "$default_branch" ]; then
        echo "$default_branch"
    else
        # Fallback to common default branch names
        if git show-ref --verify --quiet refs/heads/main; then
            echo "main"
        elif git show-ref --verify --quiet refs/heads/master; then
            echo "master"
        else
            echo ""
        fi
    fi
}

# Helper function to checkout default branch
checkout_default_branch() {
    local default_branch=$(get_default_branch)
    if [ -n "$default_branch" ]; then
        git checkout "$default_branch" 2>/dev/null || true
    fi
}

# Helper function to get remote branches
get_remote_branches() {
    git branch -r | grep -v '\->' | sed 's/origin\///'
}

# Function to clone or update a repository with all branches
backup_repository() {
    local repo_name=$1
    local clone_url=$2
    
    echo "Processing: $repo_name"
    
    if [ $USE_MIRROR -eq 1 ]; then
        backup_repository_mirror "$repo_name" "$clone_url"
    else
        backup_repository_regular "$repo_name" "$clone_url"
    fi
    
    echo ""
}

# Function to backup using mirror clone
backup_repository_mirror() {
    local repo_name=$1
    local clone_url=$2
    local mirror_name="${repo_name}.git"
    
    if [ -d "$mirror_name" ]; then
        echo "  Mirror exists, updating..."
        cd "$mirror_name"
        
        # Update all refs
        git remote update --prune
        
        cd ..
        echo "  ✓ Updated successfully"
    else
        echo "  Creating mirror clone..."
        git clone --mirror "$clone_url" "$mirror_name"
        
        if [ -d "$mirror_name" ]; then
            echo "  ✓ Cloned successfully"
        else
            echo "  ✗ Failed to clone"
        fi
    fi
}

# Function to backup using regular clone
backup_repository_regular() {
    local repo_name=$1
    local clone_url=$2
    
    if [ -d "$repo_name" ]; then
        echo "  Repository exists, updating..."
        cd "$repo_name"
        
        # Fetch all remote branches
        git fetch --all --prune
        
        # Get list of all remote branches
        remote_branches=$(get_remote_branches)
        
        # Update each branch
        for branch in $remote_branches; do
            branch=$(echo "$branch" | xargs)  # Trim whitespace
            echo "    Updating branch: $branch"
            
            # Check if local branch exists
            if git show-ref --verify --quiet "refs/heads/$branch"; then
                # Branch exists locally, check it out and pull
                git checkout "$branch" 2>/dev/null || continue
                git pull origin "$branch" 2>/dev/null || echo "      Could not pull $branch"
            else
                # Branch doesn't exist locally, create it
                git checkout -b "$branch" "origin/$branch" 2>/dev/null || echo "      Could not checkout $branch"
            fi
        done
        
        # Return to default branch
        checkout_default_branch
        
        cd ..
        echo "  ✓ Updated successfully"
    else
        echo "  Cloning repository..."
        git clone "$clone_url" "$repo_name"
        
        if [ -d "$repo_name" ]; then
            cd "$repo_name"
            
            # Fetch all branches
            git fetch --all
            
            # Get list of all remote branches and create local tracking branches
            remote_branches=$(get_remote_branches)
            
            for branch in $remote_branches; do
                branch=$(echo "$branch" | xargs)  # Trim whitespace
                
                # Check if we're not already on this branch
                current_branch=$(git rev-parse --abbrev-ref HEAD)
                if [ "$branch" != "$current_branch" ]; then
                    echo "    Creating local branch: $branch"
                    git checkout -b "$branch" "origin/$branch" 2>/dev/null || echo "      Could not create branch $branch"
                fi
            done
            
            # Return to default branch
            checkout_default_branch
            
            cd ..
            echo "  ✓ Cloned successfully"
        else
            echo "  ✗ Failed to clone"
        fi
    fi
}

# Main backup process
echo "Fetching repository list..."
repo_data=$(get_repositories "$GITHUB_USER")

if [ -z "$repo_data" ]; then
    echo "No repositories found for user: $GITHUB_USER"
    exit 0
fi

# Count repositories
repo_count=$(echo "$repo_data" | wc -l)
echo "Found $repo_count repositories"
echo "==================================="
echo ""

# Process each repository
printf '%s\n' "$repo_data" | while IFS= read -r line; do
    if [ -n "$line" ]; then
        repo_name=$(echo "$line" | cut -d'|' -f1)
        clone_url=$(echo "$line" | cut -d'|' -f2)
        backup_repository "$repo_name" "$clone_url"
    fi
done

echo "==================================="
echo "Backup completed!"
echo "All repositories backed up to: $BACKUP_DIR"
echo "==================================="
