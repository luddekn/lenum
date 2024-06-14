#!/bin/sh

# Colors
RED="\e[31m"
YELLOW="\e[33m"
LGREEN="\e[92m"
BLUE="\e[34m"

# Text Weight
BOLD="\e[1m"
ITALIC="\e[3m"
# Style Reset
RESET="\e[0m"

echo "\n"

echo "${RED}${BOLD}[*] OS / System Information${RESET}"
echo "${YELLOW}OS:${RESET} $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)"
echo "${YELLOW}OS Version:${RESET} $(grep -w 'VERSION' /etc/os-release | cut -d '"' -f 2)"
echo "${YELLOW}Linux Kernel:${RESET} $(uname -r)"
echo "${YELLOW}Hostname:${RESET} $(hostname)"

echo "\n"

echo "${RED}${BOLD}[*] Network Information${RESET}"
echo "${LGREEN}${ITALIC}# Listing all interfaces!${RESET}\n"
for interface in $(ip a | awk '/^[0-9]+:/ { sub(/:/, "", $2); print $2 }'); do
	ip=$(ip a show dev $interface | awk '/inet / {print $2}' | cut -d '/' -f 1)
	echo "${YELLOW}Interface:${RESET} $interface : $ip"
done
echo "\n"
echo "${YELLOW}Default Route:${RESET} $(ip route | grep -w "default" | cut -d " " -f 5) $(ip route | grep -w "default" | cut -d " " -f 3)"
echo "${YELLOW}DNS Nameserver:${RESET} $(cat /etc/resolv.conf | grep nameserver | cut -d ' ' -f 2)"
echo "\n"
echo "${BLUE}${BOLD}[?] Network Scan${RESET}"
for interface in $(ip a | awk '/^[0-9]+:/ { sub(/:/, "", $2); print $2 }'); do
	ip=$(ip a show dev $interface | awk '/inet / {print $2}' | cut -d '/' -f 1)
	if [ -n "$ip" ]; then
		network_address=$(echo $ip | cut -d "." -f 1-3)
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

echo "\n"

echo "${RED}${BOLD}[*] Current User Information${RESET}"
echo "${YELLOW}Current User:${RESET} $(whoami)"
echo "${YELLOW}ID:${RESET} $(id | cut -d " " -f 1-2)"
echo "${YELLOW}Groups:${RESET} $(groups)"
if [ "$(id -u)" -eq 0 ]; then
    echo "${YELLOW}[*] Sudo Privileges${RESET}"
    sudo -l
fi


echo "\n"

echo "${RED}${BOLD}[*] User Enumeration${RESET}"
echo "${LGREEN}${ITALIC}# Listing all users with shell!${RESET}\n"
for user in $(awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh|\/bin\/ksh|\/bin\/zsh|\/usr\/bin\/fish)$/ {print $1}' /etc/passwd); do
	groups=$(groups $user | cut -d ":" -f 2)
	home_dir=$(cat /etc/passwd | grep -w $user | cut -d ":" -f 6)
	if [ "$(id -u)" -eq 0 ]; then
		hash=$(awk -v user="$user" -F: '($1 == user) {print $2}' /etc/shadow 2>/dev/null)
		echo "${YELLOW}User:${RESET} $user ${YELLOW}Password Hash:${RESET} $hash ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET}$groups\n"
	else
		echo "${YELLOW}User:${RESET} $user ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET}$groups\n"
	fi
done

echo "\n"

echo "${RED}${BOLD}[*] Listing User SSH Directories${RESET}"
found_dir=false
home_dirs=$(ls /home)
for dir in $home_dirs; do
    ssh_dir=$(find /home/$dir -name ".ssh" 2>/dev/null)
    if [ -n "$ssh_dir" ]; then
        echo "${YELLOW}SSH Directory:${RESET} $ssh_dir"
        found_dir=true
    fi
done

if [ "$(id -u)" -eq 0 ]; then
    if [ -d "/root/.ssh" ]; then
        echo "${YELLOW}SSH Directory:${RESET} /root/.ssh"
        found_dir=true
    fi
fi

if ! $found_dir; then
    echo "${LGREEN}${ITALIC}# Found no .ssh directories!${RESET}"
fi

echo "\n"

echo "${RED}${BOLD}[*] Listing User History Files${RESET}"
found_file=false
home_dirs=$(ls /home)
for dir in $home_dirs; do
    for hist_file in .bash_history .zsh_history .sh_history .ksh_history .history .local/share/fish/fish_history; do
        history_file="/home/$dir/$hist_file"
        if [ -e "$history_file" ]; then
            echo "${YELLOW}History File:${RESET} $history_file"
            found_file=true
        fi
    done
done

if [ "$(id -u)" -eq 0 ]; then
    for hist_file in .bash_history .zsh_history .sh_history .ksh_history .history .local/share/fish/fish_history; do
        history_file="/root/$hist_file"
        if [ -e "$history_file" ]; then
            echo "${YELLOW}History File:${RESET} $history_file"
            found_file=true
        fi
    done
fi

if ! $found_file; then
    echo "${LGREEN}${ITALIC}# Found no history files!${RESET}"
fi

echo "\n"
