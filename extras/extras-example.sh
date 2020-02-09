#!/bin/bash

# Custom bash commands to be executed after VirtualBox is installed and launched.
# The commands will be executed by the 'amnesia' user from the 'extras' directory
# as the working directory. You must use sudo if you need elevated access.
# This is for advanced users only.

echo "Hello from extras.sh"
sudo echo "Hello from extras.sh using sudo"
echo "Current working directory: $(pwd)"
