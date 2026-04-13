# macOS MAC Address and Hostname Spoof Script

![Apple macOS](https://img.shields.io/badge/macOS-26.0-blue?logo=apple)
![signed commits](https://badgen.net/static/commits/signed/green?icon=github)

Randomize your Mac's hostname and Wi-Fi interface MAC address on every boot. A lightweight alternative to Apple's built-in private Wi-Fi address rotation — with more frequent cycling and hostname spoofing included.

> Based off Sun Knuden's [maOS Spoof Guide](https://github.com/sunknudsen/guides/tree/main/archive/how-to-spoof-mac-address-and-hostname-automatically-at-boot-on-macos)

## About

Apple's private Wi-Fi address feature rotates your MAC every two weeks. This script rotates on every restart (or whenever you call it manually), and also spoofs your hostname — which Apple's feature doesn't touch. Your hostname is broadcast over mDNS/Bonjour to every device on the local network, and a name like Johns-MacBook-Pro is personally identifiable.

### What it does

- Sets a randomized ComputerName, LocalHostName, and HostName using a real first name + your Mac's model (e.g. Riley's MacBook Pro)
- Sanitizes hostnames to be DNS-safe
- Spoofs the MAC address of en0 using a genuine Apple-registered OUI prefix so the address resolves to Apple on any network scan
- Validates inputs and fails loudly with clear error messages

> [!IMPORTANT]
> - MAC address changes do not persist across reboots or Wi-Fi toggles
> - Wi-Fi must be disconnected before 

### Files

```
spoof.sh                        # Main script
first-names.txt                 # One first name per line
mac-address-prefixes.txt        # One OUI prefix per line (XX:XX:XX uppercase hex)
local.spoof.plist               # Launch agent file to run at login
```

## Setup

### 1. Clone the repo

```zsh
git clone https://github.com/adammfurman/macos-spoof-script.git
cd macos-spoof-script
```

### 2. Make script executable

```zsh
chmod +x spoof.sh
```

### 3. Move/symlink script to local system binaries directory

```zsh
mkdir -p /usr/local/sbin

# move script
mv spoof.sh /usr/local/sbin/

# symlink script
ln -s spoof.sh /usr/local/sbin/
```


## Usage

### 1. Automatic

Spoof runs automatically upon restart via its launch agent.

### 2. Manual

Disassociate from current Wi-Fi network, but leave Wi-Fi ENABLED. Run:

```zsh
sudo spoof.sh
```

Example output: 

```zsh
Spoofed computer name to Kendra's MacBook Pro
Spoofed hostname to Kendras-MacBook-Pro
Spoofed en0 interface MAC address to E4:90:FD:CB:87:4F
```

Verify changes:

```zsh
# Hostname
scutil --get ComputerName
scutil --get LocalHostName
scutil --get HostName

# MAC address
ifconfig en0 | grep | awk {print $2}

# Hardware MAC address (this the original MAC address)
networksetup -listallhardwareports | awk -v RS= '/en0/{print $NF}'
```

## Undo everything

```zsh
rm /usr/local/sbin/first-names.txt
rm /usr/local/sbin/mac-address-prefixes.txt
rm /usr/local/sbin/spoof.sh
sudo rm /Library/LaunchAgents/local.spoof.plist
```

## License

Licenced under GPLv3.

This project contains code from Privacy Guides
Copyright (c) 2025 Sun Knudsen
Licensed under the MIT License

