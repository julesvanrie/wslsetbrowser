#!/bin/bash

# WSL Set Browser
# © Jules van Rie, 2025
# Licensed under the MIT License. See LICENSE file in the project root for full license information.
# https://www.github.com/julesvanrie/wslsetbrowser

## Color definitions for terminal output
# Reset
Color_Off='\033[0m'       # Text Reset
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Informational message
echo "This script sets BROWSER and GH_BROWSER in .zshrc and .bashrc"
echo ""

# Check if running in WSL
if ! grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
  echo -e "${Red}Error:   This script is intended to be run in WSL (Windows Subsystem for Linux).${Color_Off}"
  exit 1
fi

# Find Windows system drive and Program Files directories
win_system_drive="$(cmd.exe /c "<nul set /p=%SystemDrive%" 2>/dev/null)"
win_system_mount="$(findmnt --noheadings --first-only --output TARGET "$win_system_drive\\")"
program_files="${win_system_mount}/Program Files"
program_files_x86="${win_system_mount}/Program Files (x86)"
echo "Info:    Detected Windows system drive: $win_system_drive"
if [[ ! -d "$program_files" ]]; then
  echo -e "${Red}Error:   Could not find Program Files directories.${Color_Off}"
  exit 1
fi

# Find Windows user's home folder (needed for some browsers)
win_userprofile="$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"
win_userprofile_drive="${win_userprofile%%:*}:"
userprofile_mount="$(findmnt --noheadings --first-only --output TARGET "$win_userprofile_drive\\")"
win_userprofile_dir="${win_userprofile#*:}"
userprofile="${userprofile_mount}${win_userprofile_dir//\\//}"
appdata_local="${userprofile}/AppData/Local"
if [[ ! -d "$userprofile" ]]; then
  echo -e "${Yellow}Warning: Could not find user profile directory. Some browsers may not be detected.${Color_Off}"
else
  echo "Info:    Detected Windows user profile: $win_userprofile"
fi

# Function to convert WSL path to Windows path
function wsl_path_to_win() {
  local wsl_path="$1"
  win_path="${wsl_path/${appdata_local}/$win_userprofile\\AppData\\Local}"
  win_path="${win_path/$win_system_mount/$win_system_drive}"
  win_path="${win_path//\//\\}"
  echo "$win_path"
}

# Function to convert Windows path to WSL path
function win_path_to_wsl() {
  local win_path="$1"
  win_drive="${win_path%%:*}"
  win_path="${win_path#*:}"
  win_mount="$(findmnt --noheadings --first-only --output TARGET "${win_drive^}:\\")"
  wsl_path="${win_mount}${win_path//\\//}"
  echo "$wsl_path"
}

# Sets the BROWSER and GH_BROWSER environment variable in a file
function update_rc_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    # Remove any existing BROWSER line
    sed -i '/^export BROWSER=/d' "$file"
    sed -i '/^export GH_BROWSER=/d' "$file"
    # Add the new BROWSER line
    echo "" >> "$file"
    echo "export BROWSER=\"${known_browsers[$choice]}\"" >> "$file"
    echo "export GH_BROWSER=\"'${known_browsers[$choice]}'\"" >> "$file"
    echo -e "${Green}BROWSER and GH_BROWSER set to ${Color_Off}${known_browsers[$choice]} ${Green}in${Color_Off} $file${Color_Off}"
  else
    echo "Info: $file not found. Skipping update."
  fi
}

# List of known browsers with their paths
declare -A known_browsers
known_browsers["Chrome"]="${program_files}/Google/Chrome/Application/chrome.exe"
known_browsers["Chrome (x86)"]="${program_files_x86}/Google/Chrome/Application/chrome.exe"
known_browsers["Firefox"]="${program_files}/Mozilla Firefox/firefox.exe"
known_browsers["Firefox (x86)"]="${program_files_x86}/Mozilla Firefox/firefox.exe"
known_browsers["Edge"]="${program_files_x86}/Microsoft/Edge/Application/msedge.exe"
known_browsers["Opera"]="${program_files}/Opera/launcher.exe"
known_browsers["Brave"]="${program_files}/BraveSoftware/Brave-Browser/Application/brave.exe"
known_browsers["Zen"]="${program_files}/Zen Browser/zen.exe"
if [[ -d "${appdata_local}" ]]; then
  known_browsers["Firefox (user)"]="${appdata_local}/Microsoft/WindowsApps/firefox.exe"
  known_browsers["Brave (user)"]="${appdata_local}/BraveSoftware/Brave-Browser/Application/brave.exe"
  known_browsers["Opera"]="${appdata_local}/Programs/Opera/opera.exe"
  known_browsers["Arc"]="${appdata_local}/Microsoft/WindowsApps/Arc.exe"
fi

# Iterate over browsers and create list of available browsers' keys
available_browsers=()
for browser in "${!known_browsers[@]}"; do
  if [[ -f "${known_browsers[$browser]}" ]]; then
    available_browsers+=("${browser}")
  fi
done

# Sort available browsers alphabetically
IFS=$'\n' available_browsers=($(sort <<<"${available_browsers[*]}"))
unset IFS

# Display available browsers
echo
echo "Available browsers:"
for i in "${!available_browsers[@]}"; do
  browser_key="${available_browsers[$i]}"
  win_path="$(wsl_path_to_win "${known_browsers[$browser_key]}")"
  padded_key=$(printf "%-16s" "$browser_key")
  echo -ne "${BBlue}$((i + 1)) - ${padded_key}${Color_Off}"
  echo ${win_path}
done

# Prompt user to select a browser
echo
echo -ne "${BBlue}Select a browser by number${Color_Off} (0 to exit, 99 to provide the path to an unknown browser): "
read choice_number
# Exit if the user chooses 0
if [[ "$choice_number" -eq 0 ]]; then
  echo "Exiting without changes."
  exit 0
fi
# Allow the user to enter a custom browser path if they choose 99
if [[ "$choice_number" -eq 99 ]]; then
  read -r -p "Enter the full path to the browser executable: " custom_browser_path
  wsl_custom_browser_path="$(win_path_to_wsl $custom_browser_path)"
  # Add the custom browser to the known browsers if it exists
  if [[ -f "$wsl_custom_browser_path" ]]; then
    known_browsers["Custom Browser"]="$wsl_custom_browser_path"
    choice="Custom Browser"
  else
    echo -e "${Red}Invalid path. Exiting.${Color_Off}"
    exit 1
  fi
else
  # Get the browser key based on the user's choice
  choice=${available_browsers[$((choice_number - 1))]}
fi

# Check if the choice is valid and output the selected browser
if [[ -n "$choice" ]]; then
  echo -e "You selected: ${BGreen}$choice${Color_Off}"
  echo
else
  echo -e "${Red}Invalid selection. Exiting.${Color_Off}"
  exit 1
fi

# Update the BROWSER and GH_BROWSER environment variables in .bashrc and .zshrc
update_rc_file "$HOME/.bashrc"
update_rc_file "$HOME/.zshrc"

echo
echo -e "${BBlack}    Please restart all terminals to apply the changes.${Color_Off}"
echo
