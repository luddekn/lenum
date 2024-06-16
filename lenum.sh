#!/bin/sh

# This script is created to automate the process of doing manual
# enumeration of a Linux machine.

# Created by @ludvikkristoffersen 2024

# Colors
RED="\e[31m"
YELLOW="\e[33m"
LGREEN="\e[92m"
LCYAN="\e[96m"
CYAN="\e[36m"
LMAGENTA="\e[95m"
# Text Weight
BOLD="\e[1m"
ITALIC="\e[3m"
# Style Reset
RESET="\e[0m"

# Function to print the banner
banner() {
    echo "${RED}${BOLD}    .--.${RESET}"
    echo "${RED}${BOLD}   |o_o |  ${RESET}"
    echo "${RED}${BOLD}   |:_/ |${RESET}       ${CYAN}${BOLD}__    ______                    ${RESET}"
    echo "${RED}${BOLD}  //   \\ \\ ${RESET}    ${CYAN}${BOLD}/ /   / ____/___  __  ______ ___ ${RESET}"
    echo "${RED}${BOLD} (|     | )${RESET}   ${CYAN}${BOLD}/ /   / __/ / __ \/ / / / __ \`__ \ ${RESET}"
    echo "${RED}${BOLD}/'\\_   _/\\\`\\ ${RESET}${CYAN}${BOLD}/ /___/ /___/ / / / /_/ / / / / / / ${RESET}"
    echo "${RED}${BOLD}\\___)=(___/${RESET} ${CYAN}${BOLD}/_____/_____/_/ /_/\__,_/_/ /_/ /_/ ${RESET}"
    echo "${YELLOW}${BOLD}Linux Enumeration (2024) @ludvikkristoffersen${RESET}"
    echo ""
}

# Function to display help information
help() {
    echo ""
    echo "${YELLOW}Available commands:${RESET}"
    echo "  -> ${LMAGENTA}${BOLD}os${RESET}: Display information about the operating system."
    echo "  -> ${LMAGENTA}${BOLD}env${RESET}: Display information about the current environment."
    echo "  -> ${LMAGENTA}${BOLD}user${RESET}: Show details of the current user and information about other users."
    echo "  -> ${LMAGENTA}${BOLD}netinfo${RESET}: Display network configuration and status."
    echo "  -> ${LMAGENTA}${BOLD}netscan${RESET}: Perform a ping sweep on all network interfaces."
    echo "  -> ${LMAGENTA}${BOLD}interesting${RESET}: Identify and list interesting files or directories for further inspection."
    echo "  -> ${LMAGENTA}${BOLD}exit${RESET}: Exit the script."
    echo "  -> ${LMAGENTA}${BOLD}help${RESET}: Display this help menu."
}

sudo_pass() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "You are running as root. No need to input sudo password."
        echo ""
        return
    fi

    echo -n "Sudo password for current user '$(whoami)' (press ENTER to skip): "

    stty -echo
    read sudo_password
    stty echo
    echo

    if [ -z "$sudo_password" ]; then
        sudo_password_set=false
        echo ""
    else
        echo "Sudo password has been set!"
        sudo_password_set=true
        echo ""
    fi
}

# Function to gather OS information
os_information() {
    echo ""
    echo "${RED}${BOLD}[*] OS / System Information${RESET}"
    echo "${YELLOW}OS:${RESET} $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2 2>/dev/null)"
    echo "${YELLOW}OS Version:${RESET} $(grep -w 'VERSION' /etc/os-release | cut -d '"' -f 2 2>/dev/null)"
    echo "${YELLOW}Linux Kernel:${RESET} $(uname -r 2>/dev/null)"
    echo "${YELLOW}Hostname:${RESET} $(hostname 2>/dev/null)"
}

# Function to gather environment data
environment() {
    echo ""
    echo "${RED}${BOLD}[*] Environment Information${RESET}"
    echo "${YELLOW}User:${RESET} $USER"
    echo "${YELLOW}Home:${RESET} $HOME"
    echo "${YELLOW}Shell:${RESET} $SHELL"
    echo "${YELLOW}Working Directory:${RESET} $PWD"
    echo "${YELLOW}Session Type:${RESET} $XDG_SESSION_TYPE"
    echo "${YELLOW}Desktop Environment:${RESET} $XDG_CURRENT_DESKTOP"
    echo "${YELLOW}Language:${RESET} $LANG"
    echo "${YELLOW}Locale:${RESET} $LANGUAGE"
    echo "${YELLOW}PATH:${RESET} $PATH"
    echo "${YELLOW}SSH Agent PID:${RESET} $SSH_AGENT_PID"
    echo "${YELLOW}SSH Auth Socket:${RESET} $SSH_AUTH_SOCK"
    echo "${YELLOW}DBUS Session Bus Address:${RESET} $DBUS_SESSION_BUS_ADDRESS"
    echo "${YELLOW}Display:${RESET} $DISPLAY"
    echo "${YELLOW}X Authority File:${RESET} $XAUTHORITY"
    echo "${YELLOW}Runtime Directory:${RESET} $XDG_RUNTIME_DIR"
}

# Function to gather network information
network_info() {
    echo ""
    echo "${RED}${BOLD}[*] Network Information${RESET}"
    echo "${LGREEN}${ITALIC}# Listing all interfaces!${RESET}"
    echo ""
    for interface in $(ip a | awk '/^[0-9]+:/ { sub(/:/, "", $2); print $2 }' 2>/dev/null); do
        ip=$(ip -4 -o addr show dev "$interface" | awk '{print $4}' 2>/dev/null)
        if [ -n "$ip" ]; then
            echo "${YELLOW}Interface:${RESET} $interface : $ip"
        fi
    done

    echo ""

    echo "${YELLOW}Default Route:${RESET} $(ip route | grep -w "default" | cut -d " " -f 5) $(ip route | grep -w "default" | cut -d " " -f 3 2>/dev/null)"
    echo "${YELLOW}DNS Nameserver:${RESET} $(awk '/nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null)"

    echo ""

    if [ "$sudo_password_set" = true  ]; then
        echo "${YELLOW}Open Ports:${RESET}"
        echo "$sudo_password" | sudo -S netstat -tunlp | sed '1d' 2>/dev/null
    else
        echo "${YELLOW}Open Ports:${RESET}"
        netstat -tunlp | sed '1d' 2>/dev/null
    fi
    echo ""
}

# Function to perform network scanning
network_scan() {
    echo ""
    echo "${RED}${BOLD}[*] Network Scan${RESET}"
    for interface in $(ip a | awk '/^[0-9]+:/ { sub(/:/, "", $2); print $2 }' 2>/dev/null); do
        ip=$(ip -4 -o addr show dev $interface | awk '{print $4}' | cut -d '/' -f 1 2>/dev/null)
        if [ -n "$ip" ]; then
            network_address=$(echo $ip | cut -d "." -f 1-3 2>/dev/null)
            if [ "$network_address" = "127.0.0" ]; then
                continue
            fi
            for host in $(seq 1 254); do
                target_ip="${network_address}.${host}"
                ping -c 1 -W 1 $target_ip > /dev/null 2>&1 && echo "${YELLOW}Alive Host:${RESET} $target_ip" &
            done
            wait
        fi
    done
}

# Function to gather user information
user() {
    echo ""
    echo "${RED}${BOLD}[*] Current User Information${RESET}"
    echo "${YELLOW}Current User:${RESET} $(whoami 2>/dev/null)"
    echo "${YELLOW}ID:${RESET} $(id | cut -d " " -f 1-2 2>/dev/null)"
    echo "${YELLOW}Groups:${RESET} $(groups 2>/dev/null)"
    reading_shadow=$(cat /etc/shadow 2>/dev/null)
    if [ "$reading_shadow" ]; then
        echo "${YELLOW}Can we read shadow file without sudo?:${RESET} ${LGREEN}YES${RESET}"
    else
        echo "${YELLOW}Can we read shadow file without sudo?:${RESET} ${RED}NO${RESET}"
    fi
    accessing_root=$(ls /root 2>/dev/null)
    if [ "$accessing_root" ]; then
        echo "${YELLOW}Can we access /root without sudo?:${RESET} ${LGREEN}YES${RESET}"
    else
        echo "${YELLOW}Can we access /root without sudo?:${RESET} ${RED}NO${RESET}"
    fi
    if [ "$(id -u)" -eq 0 ]; then
        echo "${YELLOW}Sudo Privileges:${RESET}"
        sudo -l -U "$(whoami)" | sed '1,3d' 2>/dev/null
    else
        if [ "$sudo_password_set" = true  ]; then
            echo "${YELLOW}Sudo Privileges:${RESET}"
            echo "$sudo_password" | sudo -S -l | sed '1,3d' 2>/dev/null
        fi
    fi

    echo ""

    echo "${RED}${BOLD}[*] Other User Enumeration${RESET}"
    echo "${LGREEN}${ITALIC}# Listing all users with shell!${RESET}"
    echo ""
    awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh|\/bin\/ksh|\/bin\/zsh|\/usr\/bin\/fish)$/ {print $1}' /etc/passwd 2>/dev/null | while read -r user; do
        groups=$(groups "$user" | cut -d ":" -f 2 2>/dev/null)
        home_dir=$(getent passwd "$user" | cut -d ":" -f 6 2>/dev/null)
        if [ "$(id -u)" -eq 0 ]; then
            hash=$(awk -v user="$user" -F: '($1 == user) {print $2}' /etc/shadow 2>/dev/null)
            echo "${YELLOW}User:${RESET} $user ${YELLOW}Password Hash:${RESET} $hash ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET} $groups\n"
        else
            if [ "$sudo_password_set" = true  ]; then
                hash=$(echo "$sudo_password" | sudo -S awk -v user="$user" -F: '($1 == user) {print $2}' /etc/shadow 2>/dev/null)
                echo "${YELLOW}User:${RESET} $user ${YELLOW}Password Hash:${RESET} $hash ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET} $groups\n"
            else
                echo "${YELLOW}User:${RESET} $user ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET} $groups\n"
            fi
        fi
    done

    echo "${RED}${BOLD}[*] List of Root Users${RESET}"
    root_users=$(cat /etc/passwd 2>/dev/null | awk -F: '$3 == 0 { print $1}' 2>/dev/null)
    if [ "$root_users" ]; then
        for user in $root_users; do
            echo "${YELLOW}User:${RESET} $user"
        done
    else
        echo "${LGREEN}${ITALIC}# Found no root user's!${RESET}"
    fi
}

# Function to gather interesting files and directories
interesting() {
    echo ""
    echo "${RED}${BOLD}[*] Listing User SSH Directories${RESET}"
    found_dir=false
    for dir in /home/*; do
        ssh_dir=$(find "$dir" -name ".ssh" 2>/dev/null)
        if [ -n "$ssh_dir" ]; then
            echo "${YELLOW}SSH Directory:${RESET} $ssh_dir"
            found_dir=true
        fi
    done

    if [ "$(id -u)" -eq 0 ] && [ -d "/root/.ssh" ]; then
        echo "${YELLOW}SSH Directory:${RESET} /root/.ssh"
        found_dir=true
    elif [ "$sudo_password_set" = true ]; then
        ssh_dir=$(echo "$sudo_password" | sudo -S find /root -name ".ssh" 2>/dev/null)
        if [ -n "$ssh_dir" ]; then
            echo "${YELLOW}SSH Directory:${RESET} $ssh_dir"
            found_dir=true
        fi
    fi

    if [ "$found_dir" = false ]; then
        echo "${LGREEN}${ITALIC}# Found no .ssh directories!${RESET}"
    fi

    echo ""

    echo "${RED}${BOLD}[*] Listing User History Files${RESET}"
    found_file=false
    for dir in /home/*; do
        for hist_file in "$dir"/.bash_history "$dir"/.zsh_history "$dir"/.sh_history "$dir"/.ksh_history "$dir"/.history "$dir"/.local/share/fish/fish_history; do
            if [ -e "$hist_file" ]; then
                echo "${YELLOW}History File:${RESET} $hist_file"
                found_file=true
            fi
        done
    done

    if [ "$(id -u)" -eq 0 ]; then
        for hist_file in /root/.bash_history /root/.zsh_history /root/.sh_history /root/.ksh_history /root/.history /root/.local/share/fish/fish_history; do
            if [ -e "$hist_file" ]; then
                echo "${YELLOW}History File:${RESET} $hist_file"
                found_file=true
            fi
        done
    elif [ "$sudo_password_set" = true ]; then
        for hist_file in /root/.bash_history /root/.zsh_history /root/.sh_history /root/.ksh_history /root/.history /root/.local/share/fish/fish_history; do
            if echo "$sudo_password" | sudo -S test -e "$hist_file" 2>/dev/null; then
                echo "${YELLOW}History File:${RESET} $hist_file"
                found_file=true
            fi
        done
    fi

    if [ "$found_file" = false ]; then
        echo "${LGREEN}${ITALIC}# Found no history files!${RESET}"
    fi
}

strip_colors() {
    sed -r "s/\x1B\[[0-9;]*[mK]//g"
}

# Starting script
echo ""
banner
echo "Type 'help' to see available commands!"
sudo_pass
generate_html() {
    OUTPUT_FILE="$1"
    COMMANDS_FILE="$2"
    TEMP_FILE=$(mktemp)

    # Extract unique commands
    sort -u "$COMMANDS_FILE" > "$TEMP_FILE"

    # HTML header and initial styling
    cat <<EOF > "$OUTPUT_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Linux Enumeration Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            line-height: 1.6;
        }
        h1, h2, h3 {
            color: #333;
            border-bottom: 1px solid #ccc;
            padding-bottom: 5px;
            margin-bottom: 20px;
        }
        pre {
            background-color: #f9f9f9;
            padding: 10px;
            border-radius: 5px;
            white-space: pre-wrap;
            overflow-x: auto;
        }
    </style>
</head>
<body>
<h1>Linux Enumeration Report</h1>
<p>Generated on $(date)</p>
EOF

    # Command sections in HTML
    while IFS= read -r command; do
        case "$command" in
            "os")
                echo "<h3>OS Information</h3>" >> "$OUTPUT_FILE"
                echo "<pre>" >> "$OUTPUT_FILE"
                os | strip_colors >> "$OUTPUT_FILE"
                echo "</pre>" >> "$OUTPUT_FILE"
                ;;
            "env")
                echo "<h3>Environment Information</h3>" >> "$OUTPUT_FILE"
                echo "<pre>" >> "$OUTPUT_FILE"
                environment | strip_colors >> "$OUTPUT_FILE"
                echo "</pre>" >> "$OUTPUT_FILE"
                ;;
            "netinfo")
                echo "<h3>Network Information</h3>" >> "$OUTPUT_FILE"
                echo "<pre>" >> "$OUTPUT_FILE"
                network_info | strip_colors >> "$OUTPUT_FILE"
                echo "</pre>" >> "$OUTPUT_FILE"
                ;;
            "netscan")
                echo "<h3>Network Scan</h3>" >> "$OUTPUT_FILE"
                echo "<pre>" >> "$OUTPUT_FILE"
                network_scan | strip_colors >> "$OUTPUT_FILE"
                echo "</pre>" >> "$OUTPUT_FILE"
                ;;
            "user")
                echo "<h3>User Information</h3>" >> "$OUTPUT_FILE"
                echo "<pre>" >> "$OUTPUT_FILE"
                user | strip_colors >> "$OUTPUT_FILE"
                echo "</pre>" >> "$OUTPUT_FILE"
                ;;
            "interesting")
                echo "<h3>Interesting Information</h3>" >> "$OUTPUT_FILE"
                echo "<pre>" >> "$OUTPUT_FILE"
                interesting | strip_colors >> "$OUTPUT_FILE"
                echo "</pre>" >> "$OUTPUT_FILE"
                ;;
        esac
    done < "$TEMP_FILE"

    # HTML footer
    cat <<EOF >> "$OUTPUT_FILE"
</body>
</html>
EOF

    echo "${LGREEN}HTML report generated: $OUTPUT_FILE${RESET}"
    
    # Clean up temporary file
    rm "$TEMP_FILE"
}

# Main program starts here
if [ "$1" = "-o" ]; then
    if [ -z "$2" ]; then
        echo "Please provide a filename for the HTML report."
        exit 1
    fi
    OUTPUT_FILE="$2"
    shift 2
    COMMAND_FILE=$(mktemp)
    while true; do
        read -p "$(echo "${LCYAN}${BOLD}lenum${RESET}# ")" command
		case "$command" in
			"help")
				help
				;;
			"os")
				os_information
				;;
            "env")
                environment
                ;;
			"netinfo")
				network_info
				;;
			"netscan")
				network_scan
				;;
			"user")
				user
				;;
			"interesting")
				interesting
				;;
			"exit")
				echo "${RED}Exiting lenum script.${RESET}"
                echo ""
				generate_html "$OUTPUT_FILE" "$COMMAND_FILE"
				rm "$COMMAND_FILE"  # Clean up temporary command file
                unset sudo_password
				exit 0
				;;
			*)
				echo "${RED}Unknown command: '${command}'. Type 'help' for available commands.${RESET}"
				;;
		esac
		echo ""
    done
else
    while true; do
        read -p "$(echo "${LCYAN}${BOLD}lenum${RESET}# ")" command
        case "$command" in
            "help")
                help
                ;;
            "os")
                os_information
                ;;
            "env")
                environment
                ;;
            "netinfo")
                network_info
                ;;
            "netscan")
                network_scan
                ;;
            "user")
                user
                ;;
            "interesting")
                interesting
                ;;
            "exit")
                echo "${RED}Exiting lenum script.${RESET}"
                echo ""
                unset sudo_password
                exit 0
                ;;
            *)
                echo "${RED}Unknown command: '${command}'. Type 'help' for available commands.${RESET}"
                ;;
        esac
        echo ""
    done
fi