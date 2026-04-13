#! /bin/zsh

# This file contains code from Privacy Guides
# Copyright (c) 2025 Sun Knudsen
# Licensed under the MIT License.   

# --- Error Handling ------------------------------------------------------------------------

# -e: exit immediately upon non-zero exit code
# -u: treat unset variables as an error and exit immediately if used
# -o pipefail: make pipeline fail if any command within it fails
set -euo pipefail
# process text using US-ASCII in case names use non-US characters
export LC_CTYPE=C

# ---- Helper Functions ---------------------------------------------------------------------

# Failsafe: exit safely upon error with exit code 1 and info
failsafe() { printf "ERROR: %s\n" "$*" >&2; exit 1; }

# --- Resolve Script Directory --------------------------------------------------------------

# Resolve symlinks and give aboslute path so that script works regardless of call location
basedir=$(cd "$(dirname "$0")" && pwd)
names_file="$basedir/first-names.txt"
mac_file="$basedir/mac-address-prefixes.txt"

# Check if names file exists
[[ -f "$names_file" ]] || failsafe "first-names.txt not found at: $names_file"

# Pull genuine Apple OUIs from IEEE into mac-address-prefixes.txt
if [[ ! -f "$mac_file" ]] then
    curl -s https://standards-oui.ieee.org/oui/oui.csv \
        | grep -i "apple" \
        | awk -F',' '{print $2}' \
        | sed 's/\(..\)\(..\)\(..\)/\1:\2:\3/' \
        | awk '{print toupper($0)}' \
        > mac-address-prefixes.txt
fi


# --- Ensure Text Files are not Empty -------------------------------------------------------

# Check line count of text files
names_count=$(wc -l < "$names_file")
mac_count=$(wc -l < "$mac_file")

# If empty, exit
[[ "$names_count" -gt 0 ]] || failsafe "first-names.txt is empty"
[[ "$mac_count" -gt 0 ]] || failsafe "mac-address-prefixes.txt is empty"

# --- Spoof Computer / Host Name -------------------------------------------------------------

# Get a random name from the names list
first_name=$(sed "$(jot -r 1 1 $names_count)q;d" $names_file | sed -e 's/[^a-zA-Z]//g')
[[ -n "$first_name" ]] || failsafe "Could not get a valid first name (check first-names.txt for non-alpha lines)"

# Get computer Model Name
model_name=$(system_profiler SPHardwareDataType > /dev/null 2>&1 | awk -F': ' '/Model Name/{print $2}')
[[ -n "$model_name" ]] || failsafe "Could not get Model Name from system_profiler"

# Create full computer / host name
computer_name="${first_name}'s ${model_name}"

# Create DNS-safe hostname
#   • drop apostrophe, change spaces to hyphens, collapse runs, strip leading/trailing hyphens 
host_name=$(printf '%s' "$computer_name" | sed -e "s/'//g" -e 's/ /-/g' -e 's/-\{2,\}/-/g' -e 's/^-//' -e 's/-$//')

# Set ComputerName (user-friendly identiifer)
sudo scutil --set ComputerName "$computer_name"
# # Set LocalHostName (name for Bonjour services)
sudo scutil --set LocalHostName "$host_name"
# # Set HostName (name used for DNS and network resolution) 
sudo scutil --set HostName "$host_name"

# Print new computer/host names
echo "Spoofed computer name to $computer_name"
echo "Spoofed hostname to $host_name"

# --- Spoof MAC Address (en0 interface) --------------------------------------------------------

# Get an organizational unique identifier (OUI)
#   • First 6 digits (3 octets) in hex of MAC address that identifies manufacturer
oui=$(sed "$(jot -r 1 1 $mac_count)q;d" $mac_file | sed -e 's/[^A-F0-9:]//g')
[[ -n "$oui" ]] || failsafe "Could not get a valid OUI prefix (check mac-address-prefixes.txt)"

# Get a randomly generated hex MAC address suffix
suffix=$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/.$//')

# Create spoofed MAC address
mac_address=$(printf '%s:%s' "$oui" "$suffix" | awk '{print toupper($0)}')

# Set spoofed MAC address
#   • Capture error if fail and pass to failsafe()
err=$(sudo ifconfig en0 ether "$mac_address" 2>&1) || failsafe "$err (make sure WiFi is ON and DISCONNECTED)"

# Print new MAC address
echo "Spoofed en0 interface MAC address to $mac_address"
