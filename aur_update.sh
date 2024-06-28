#!/bin/bash

# Function to check if a package is installed
is_installed() {
    pacman -Q $1 &> /dev/null
}

# Loop through each directory in the current path
for dir in */; do
    # Remove the trailing slash from directory name
    package=${dir%/}
    
    # Check if the package is installed
    if is_installed $package; then
        echo "Updating $package..."
        
        # Change to the package directory
        cd $dir
        
        # Pull the latest changes from the AUR
        git pull
        
        # Build and install the package
        makepkg -si --noconfirm
        
        # Return to the parent directory
        cd ..
    else
        echo "Skipping $package as it is not installed."
    fi
done
