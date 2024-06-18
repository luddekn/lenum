#!/bin/bash

# This script is created to automate the process of doing manual
# enumeration of a Linux machine.

# Created by @ludvikkristoffersen 2024

# Colors
RED="\033[31m"
YELLOW="\033[33m"
LGREEN="\033[92m"
LCYAN="\033[96m"
CYAN="\033[36m"
LMAGENTA="\033[95m"
# Text Weight
BOLD="\033[1m"
ITALIC="\033[3m"
# Style Reset
RESET="\033[0m"

# Function to print the banner
banner() {
    printf "${RED}${BOLD}    .--.${RESET}\n"
    printf "${RED}${BOLD}   |o_o |  ${RESET}\n"
    printf "${RED}${BOLD}   |:_/ |${RESET}       ${CYAN}${BOLD}__    ______                    ${RESET}\n"
    printf "${RED}${BOLD}  //   \\ \\ ${RESET}    ${CYAN}${BOLD}/ /   / ____/___  __  ______ ___ ${RESET}\n"
    printf "${RED}${BOLD} (|     | )${RESET}   ${CYAN}${BOLD}/ /   / __/ / __ \/ / / / __ \`__ \ ${RESET}\n"
    printf "${RED}${BOLD}/'\\_   _/\\\`\\ ${RESET}${CYAN}${BOLD}/ /___/ /___/ / / / /_/ / / / / / / ${RESET}\n"
    printf "${RED}${BOLD}\\___)=(___/${RESET} ${CYAN}${BOLD}/_____/_____/_/ /_/\__,_/_/ /_/ /_/ ${RESET}\n"
    printf "${YELLOW}${BOLD}Linux Enumeration (2024) @ludvikkristoffersen${RESET}\n"
}

# Function to display help information
help() {
    printf "\n"
    printf "${YELLOW}Available commands:${RESET}\n"
    printf "  -> ${LMAGENTA}${BOLD}os${RESET}: Display information about the operating system.\n"
    printf "  -> ${LMAGENTA}${BOLD}env${RESET}: Display information about the current environment.\n"
    printf "  -> ${LMAGENTA}${BOLD}user${RESET}: Show details of the current user and information about other users.\n"
    printf "  -> ${LMAGENTA}${BOLD}netinfo${RESET}: Display network configuration and status.\n"
    printf "  -> ${LMAGENTA}${BOLD}netscan${RESET}: Perform a ping sweep on all network interfaces.\n"
    printf "  -> ${LMAGENTA}${BOLD}interesting${RESET}: Identify and list interesting files or directories for further inspection.\n"
    printf "  -> ${LMAGENTA}${BOLD}exit${RESET}: Exit the script.\n"
    printf "  -> ${LMAGENTA}${BOLD}help${RESET}: Display this help menu.\n"
}

sudo_pass() {
    if [ "$(id -u)" -eq 0 ]; then
        printf "You are running as root. No need to input sudo password.\n\n"
        return
    fi

    printf "Sudo password for current user '$(whoami)' (press ENTER to skip): "
    read -s sudo_password

    if [ -z "$sudo_password" ]; then
        sudo_password_set=false
        printf "\n\n"
    else
        printf "\nSudo password has been set.\n\n"
        sudo_password_set=true
    fi
}

# Function to gather OS information
os_information() {
    printf "\n"
    printf "${RED}${BOLD}[*] OS / System Information${RESET}\n"
    printf "${YELLOW}OS:${RESET} $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2 2>/dev/null)\n"
    printf "${YELLOW}OS Version:${RESET} $(grep -w 'VERSION' /etc/os-release | cut -d '"' -f 2 2>/dev/null)\n"
    printf "${YELLOW}Linux Kernel:${RESET} $(uname -r 2>/dev/null)\n"
    printf "${YELLOW}Hostname:${RESET} $(hostname 2>/dev/null)\n"
}

# Function to gather environment data
environment() {
    printf "\n"
    printf "${RED}${BOLD}[*] Environment Information${RESET}\n"
    printf "${YELLOW}User:${RESET} $USER\n"
    printf "${YELLOW}Home:${RESET} $HOME\n"
    printf "${YELLOW}Shell:${RESET} $SHELL\n"
    printf "${YELLOW}Working Directory:${RESET} $PWD\n"
    printf "${YELLOW}Session Type:${RESET} $XDG_SESSION_TYPE\n"
    printf "${YELLOW}Desktop Environment:${RESET} $XDG_CURRENT_DESKTOP\n"
    printf "${YELLOW}Language:${RESET} $LANG\n"
    printf "${YELLOW}Locale:${RESET} $LANGUAGE\n"
    printf "${YELLOW}PATH:${RESET} $PATH\n"
    printf "${YELLOW}SSH Agent PID:${RESET} $SSH_AGENT_PID\n"
    printf "${YELLOW}SSH Auth Socket:${RESET} $SSH_AUTH_SOCK\n"
    printf "${YELLOW}DBUS Session Bus Address:${RESET} $DBUS_SESSION_BUS_ADDRESS\n"
    printf "${YELLOW}Display:${RESET} $DISPLAY\n"
    printf "${YELLOW}X Authority File:${RESET} $XAUTHORITY\n"
    printf "${YELLOW}Runtime Directory:${RESET} $XDG_RUNTIME_DIR\n"
}

# Function to gather network information
network_info() {
    printf "\n"
    printf "${RED}${BOLD}[*] Network Information${RESET}\n"
    printf "${LGREEN}${ITALIC}# Listing all interfaces!${RESET}\n"
    for interface in $(ip a | awk '/^[0-9]+:/ { sub(/:/, "", $2); print $2 }' 2>/dev/null); do
        ip=$(ip -4 -o addr show dev "$interface" | awk '{print $4}' 2>/dev/null)
        if [ -n "$ip" ]; then
            printf "${YELLOW}Interface:${RESET} $interface : $ip\n"
        fi
    done

    printf "\n"

    printf "${YELLOW}Default Route:${RESET} $(ip route | grep -w "default" | cut -d " " -f 5) $(ip route | grep -w "default" | cut -d " " -f 3 2>/dev/null)\n"
    printf "${YELLOW}DNS Nameserver:${RESET} $(awk '/nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null)\n"

    printf "\n"

    if [ "$sudo_password_set" = true  ]; then
        printf "${YELLOW}Open Ports:${RESET}\n"
        printf "$sudo_password" | sudo -S netstat -tunlp 2>/dev/null | sed '1d'
    else
        printf "${YELLOW}Open Ports:${RESET}\n"
        netstat -tunlp 2>/dev/null | sed '1d'
    fi
    printf "\n"
}

# Function to perform network scanning
network_scan() {
    printf "\n"
    printf "${RED}${BOLD}[*] Network Scan${RESET}\n"
    for interface in $(ip a | awk '/^[0-9]+:/ { sub(/:/, "", $2); print $2 }' 2>/dev/null); do
        ip=$(ip -4 -o addr show dev $interface | awk '{print $4}' | cut -d '/' -f 1 2>/dev/null)
        if [ -n "$ip" ]; then
            network_address=$(printf $ip | cut -d "." -f 1-3 2>/dev/null)
            if [ "$network_address" = "127.0.0" ]; then
                continue
            fi
            for host in $(seq 1 254); do
                target_ip="${network_address}.${host}"
                ping -c 1 -W 1 $target_ip > /dev/null 2>&1 && printf "${YELLOW}Alive Host:${RESET} $target_ip\n" &
            done
            wait
        fi
    done
}

# Function to gather user information
user() {
    printf "\n"
    printf "${RED}${BOLD}[*] Current User Information${RESET}\n"
    printf "${YELLOW}Current User:${RESET} $(whoami 2>/dev/null)\n"
    printf "${YELLOW}ID:${RESET} $(id 2>/dev/null | cut -d " " -f 1-2)\n"
    printf "${YELLOW}Groups:${RESET} $(groups 2>/dev/null)\n"
    reading_shadow=$(cat /etc/shadow 2>/dev/null)
    if [ "$reading_shadow" ]; then
        printf "${YELLOW}Can we read shadow file without sudo?:${RESET} ${LGREEN}YES${RESET}\n"
    else
        printf "${YELLOW}Can we read shadow file without sudo?:${RESET} ${RED}NO${RESET}\n"
    fi
    accessing_root=$(ls /root 2>/dev/null)
    if [ "$accessing_root" ]; then
        printf "${YELLOW}Can we access /root without sudo?:${RESET} ${LGREEN}YES${RESET}\n"
    else
        printf "${YELLOW}Can we access /root without sudo?:${RESET} ${RED}NO${RESET}\n"
    fi
    if [ "$(id -u)" -eq 0 ]; then
        printf "${YELLOW}Sudo Privileges:${RESET}\n"
        sudo -l -U "$(whoami)" 2>/dev/null | sed '1,3d'
    else
        if [ "$sudo_password_set" = true  ]; then
            printf "${YELLOW}Sudo Privileges:${RESET}\n"
            printf "$sudo_password" | sudo -S -l -U "$(whoami)" 2>/dev/null | sed '1,3d'
        fi
    fi

    printf "\n"

    printf "${RED}${BOLD}[*] Other User Enumeration${RESET}\n"
    printf "${LGREEN}${ITALIC}# Listing all users with shell!${RESET}\n\n"
    awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh|\/bin\/ksh|\/bin\/zsh|\/usr\/bin\/fish)$/ {print $1}' /etc/passwd 2>/dev/null | while read -r user; do
        groups=$(groups "$user" 2>/dev/null | cut -d ":" -f 2)
        home_dir=$(getent passwd "$user" 2>/dev/null | cut -d ":" -f 6)
        if [ "$(id -u)" -eq 0 ]; then
            hash=$(awk -v user="$user" -F: '($1 == user) {print $2}' /etc/shadow 2>/dev/null)
            printf "${YELLOW}User:${RESET} $user ${YELLOW}Password Hash:${RESET} $hash ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET}$groups\n\n"
        else
            if [ "$sudo_password_set" = true  ]; then
                hash=$(printf "$sudo_password" | sudo -S awk -v user="$user" -F: '($1 == user) {print $2}' /etc/shadow 2>/dev/null)
                printf "${YELLOW}User:${RESET} $user ${YELLOW}Password Hash:${RESET} $hash ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET}$groups\n\n"
            else
                printf "${YELLOW}User:${RESET} $user ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET}$groups\n\n"
            fi
        fi
    done

    printf "${RED}${BOLD}[*] List of Root Users${RESET}\n"
    root_users=$(cat /etc/passwd 2>/dev/null | awk -F: '$3 == 0 { print $1}')
    if [ "$root_users" ]; then
        for user in $root_users; do
            printf "${YELLOW}User:${RESET} $user\n"
        done
    else
        printf "${LGREEN}${ITALIC}# Found no root user account's.${RESET}\n"
    fi
}

# Function to gather interesting files and directories
interesting() {
    printf "\n"
    printf "${RED}${BOLD}[*] Listing User SSH Directories${RESET}\n"
    found_dir=false
    for dir in /home/*; do
        ssh_dir=$(find "$dir" -name ".ssh" 2>/dev/null)
        if [ -n "$ssh_dir" ]; then
            printf "${YELLOW}SSH Directory:${RESET} $ssh_dir\n"
            found_dir=true
        fi
    done

    if [ "$(id -u)" -eq 0 ] && [ -d "/root/.ssh" ]; then
        printf "${YELLOW}SSH Directory:${RESET} /root/.ssh\n"
        found_dir=true
    elif [ "$sudo_password_set" = true ]; then
        ssh_dir=$(printf "$sudo_password" | sudo -S find /root -name ".ssh" 2>/dev/null)
        if [ -n "$ssh_dir" ]; then
            printf "${YELLOW}SSH Directory:${RESET} $ssh_dir\n"
            found_dir=true
        fi
    fi

    if [ "$found_dir" = false ]; then
        printf "${LGREEN}${ITALIC}# Found no .ssh directories.${RESET}\n"
    fi

    printf "\n"

    printf "${RED}${BOLD}[*] Listing User History Files${RESET}\n"
    found_file=false
    for dir in /home/*; do
        for hist_file in "$dir"/.bash_history "$dir"/.zsh_history "$dir"/.sh_history "$dir"/.ksh_history "$dir"/.history "$dir"/.local/share/fish/fish_history; do
            if [ -e "$hist_file" ]; then
                printf "${YELLOW}History File:${RESET} $hist_file\n"
                found_file=true
            fi
        done
    done

    if [ "$(id -u)" -eq 0 ]; then
        for hist_file in /root/.bash_history /root/.zsh_history /root/.sh_history /root/.ksh_history /root/.history /root/.local/share/fish/fish_history; do
            if [ -e "$hist_file" ]; then
                printf "${YELLOW}History File:${RESET} $hist_file\n"
                found_file=true
            fi
        done
    elif [ "$sudo_password_set" = true ]; then
        for hist_file in /root/.bash_history /root/.zsh_history /root/.sh_history /root/.ksh_history /root/.history /root/.local/share/fish/fish_history; do
            if printf "$sudo_password" | sudo -S test -e "$hist_file" 2>/dev/null; then
                printf "${YELLOW}History File:${RESET} $hist_file\n"
                found_file=true
            fi
        done
    fi

    if [ "$found_file" = false ]; then
        printf "${LGREEN}${ITALIC}# Found no history files.${RESET}\n"
    fi
}

strip_colors() {
    sed -r "s/\x1B\[[0-9;]*[mK]//g"
}

# Starting script
banner
printf "\nType 'help' to see available commands!\n"
sudo_pass
generate_html() {
    OUTPUT_FILE="output/$1"
    COMMAND_NAME="$2"
    OUTPUT=$(cat)

    # HTML header and initial styling
    cat > "$OUTPUT_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${COMMAND_NAME} Output</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            line-height: 1.6;
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
<h1>${COMMAND_NAME} Output</h1>
<p>Created on $(date)</p>
<p>>> <a href="../index.html">Go Back</a></p>
<pre>
${OUTPUT}
</pre>
</body>
</html>
EOF
}

# Function to create index.html file with links to all generated HTML files
create_index_html() {
    printf "<!DOCTYPE html>\n" > index.html
    printf "<html lang=\"en\">\n" >> index.html
    printf "<head>\n" >> index.html
    printf "<meta charset=\"UTF-8\">\n" >> index.html
    printf "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n" >> index.html
    printf "<title>Enumeration Report</title>\n" >> index.html
    printf "<style>\n" >> index.html
    printf "    body {\n" >> index.html
    printf "        font-family: Arial, sans-serif;\n" >> index.html
    printf "        margin: 20px;\n" >> index.html
    printf "        line-height: 1.6;\n" >> index.html
    printf "    }\n" >> index.html
    printf "    table {\n" >> index.html
    printf "        width: 80%%;\n" >> index.html
    printf "        border-collapse: collapse;\n" >> index.html
    printf "        margin-top: 20px;\n" >> index.html
    printf "    }\n" >> index.html
    printf "    th, td {\n" >> index.html
    printf "        border: 1px solid #ddd;\n" >> index.html
    printf "        padding: 8px;\n" >> index.html
    printf "        text-align: left;\n" >> index.html
    printf "    }\n" >> index.html
    printf "    th {\n" >> index.html
    printf "        background-color: #f2f2f2;\n" >> index.html
    printf "    }\n" >> index.html
    printf "</style>\n" >> index.html
    printf "</head>\n" >> index.html
    printf "<body>\n" >> index.html
    printf "<h1>Enumeration Report</h1>\n" >> index.html
    printf "<p>Created on %s</p>\n" "$(date)" >> index.html
    printf "<table>\n" >> index.html
    printf "<tr>\n" >> index.html
    printf "<th>Result</th><th>Link</th>\n" >> index.html
    printf "</tr>\n" >> index.html

    for file in output/*.html; do
        filename=$(basename "$file" .html)
        filename_without_underscore=$(printf "$filename" | sed 's/_/ /g')
        printf "<tr>\n" >> index.html
        printf "<td>%s</td>\n" "$filename_without_underscore" >> index.html
        printf "<td><a href=\"%s\">View</a></td>\n" "$file" >> index.html
        printf "</tr>\n" >> index.html
    done

    printf "</table>\n" >> index.html
    printf "</body>\n" >> index.html
    printf "</html>\n" >> index.html
}

# Main program starts here
if [ "$1" = "-o" ]; then
    mkdir -p output
    shift
    while true; do
        printf "${LCYAN}${BOLD}lenum${RESET}# "
        read command
        case "$command" in
            "help")
                help
                ;;
            "os")
                os_command=$(os_information)
                printf "${os_command}"
                printf "${os_command}" | strip_colors | generate_html "os_information.html" "OS Information"
                ;;
            "env")
                environment_command=$(environment)
                printf "${environment_command}"
                printf "${environment_command}" | strip_colors | generate_html "environment_information.html" "Environment Information"
                ;;
            "netinfo")
                netinfo_command=$(network_info)
                printf "${netinfo_command}"
                printf "${netinfo_command}" | strip_colors | generate_html "network_information.html" "Network Information"
                ;;
            "netscan")
                netscan_command=$(network_scan)
                printf "${netscan_command}"
                printf "${netscan_command}" | strip_colors | generate_html "network_scan.html" "Network Scan"
                ;;
            "user")
                user_command=$(user)
                printf "${user_command}"
                printf "${user_command}" | strip_colors | generate_html "user_information.html" "User Information"
                ;;
            "interesting")
                interesting_command=$(interesting)
                printf "${interesting_command}"
                printf "${interesting_command}" | strip_colors | generate_html "interesting_information.html" "Interesting Information"
                ;;
            "exit")
                printf "\n${RED}Exiting enum script.${RESET}\n"
                unset sudo_password
                create_index_html
                printf "${LGREEN}Created index.html file.${RESET}\n\n"
                exit 0
                ;;
            *)
                printf "\n${RED}Unknown command: '${RESET}${command}${RED}'. Type 'help' for available commands.${RESET}\n"
                ;;
        esac
        printf "\n"
    done
else
    while true; do
        printf "${LCYAN}${BOLD}lenum${RESET}# "
        read command
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
                printf "\n${RED}Exiting enum script.${RESET}\n"
                unset sudo_password
                exit 0
                ;;
            *)
                printf "\n${RED}Unknown command: '${RESET}${command}${RED}'. Type 'help' for available commands.${RESET}\n"
                ;;
        esac
        printf "\n"
    done
fi