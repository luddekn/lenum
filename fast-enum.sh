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
# Text Weight
BOLD="\e[1m"
ITALIC="\e[3m"
# Style Reset
RESET="\e[0m"

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

help() {
	echo ""
	echo "${YELLOW}Available commands:${RESET}"
	echo "- os, netinfo, netscan, user, interesting, help, exit"
}

os() {
	echo ""
	echo "${RED}${BOLD}[*] OS / System Information${RESET}"
	echo "${YELLOW}OS:${RESET} $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)"
	echo "${YELLOW}OS Version:${RESET} $(grep -w 'VERSION' /etc/os-release | cut -d '"' -f 2)"
	echo "${YELLOW}Linux Kernel:${RESET} $(uname -r)"
	echo "${YELLOW}Hostname:${RESET} $(hostname)"
}

network_info() {
	echo ""
	echo "${RED}${BOLD}[*] Network Information${RESET}"
	echo "${LGREEN}${ITALIC}# Listing all interfaces!${RESET}\n"
	for interface in $(ip a | awk '/^[0-9]+:/ { sub(/:/, "", $2); print $2 }'); do
		ip=$(ip a show dev "$interface" | awk '/inet / {print $2}' | cut -d '/' -f 1)
		if [ -n "$ip" ]; then
			echo "${YELLOW}Interface:${RESET} $interface : $ip"
		fi
	done

	echo "\n"
	echo "${YELLOW}Default Route:${RESET} $(ip route | grep -w "default" | cut -d " " -f 5) $(ip route | grep -w "default" | cut -d " " -f 3)"
	echo "${YELLOW}DNS Nameserver:${RESET} $(awk '/nameserver/ {print $2}' /etc/resolv.conf)"
}

network_scan() {
	echo ""
	echo "${RED}${BOLD}[*] Network Scan${RESET}"
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
}

user() {
	echo ""
	echo "${RED}${BOLD}[*] Current User Information${RESET}"
	echo "${YELLOW}Current User:${RESET} $(whoami)"
	echo "${YELLOW}ID:${RESET} $(id | cut -d " " -f 1-2)"
	echo "${YELLOW}Groups:${RESET} $(groups)"
	echo "${YELLOW}Sudo Privileges${RESET}"
	sudo -l -U "$(whoami)" | sed '1d; 2d; 3d'

	echo "\n"

	echo "${RED}${BOLD}[*] User Enumeration${RESET}"
	echo "${LGREEN}${ITALIC}# Listing all users with shell!${RESET}\n"
	awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh|\/bin\/ksh|\/bin\/zsh|\/usr\/bin\/fish)$/ {print $1}' /etc/passwd | while read -r user; do
		groups=$(groups "$user" | cut -d ":" -f 2)
		home_dir=$(getent passwd "$user" | cut -d ":" -f 6)
		if [ "$(id -u)" -eq 0 ]; then
			hash=$(awk -v user="$user" -F: '($1 == user) {print $2}' /etc/shadow 2>/dev/null)
			echo "${YELLOW}User:${RESET} $user ${YELLOW}Password Hash:${RESET} $hash ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET} $groups\n"
		else
			echo "${YELLOW}User:${RESET} $user ${YELLOW}Home Directory:${RESET} $home_dir ${YELLOW}Groups:${RESET} $groups\n"
		fi
	done
}

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
	fi

	if ! $found_dir; then
		echo "${LGREEN}${ITALIC}# Found no .ssh directories!${RESET}"
	fi

	echo "\n"

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
	fi

	if ! $found_file; then
		echo "${LGREEN}${ITALIC}# Found no history files!${RESET}"
	fi
}

banner
echo "Type 'help' to see available commands!"
while true; do
	read -p "$(echo "${LCYAN}${BOLD}lenum${RESET}# ")" command
	
	case "$command" in
		"help")
			help
			;;
		"os")
			os
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
		"all")
			os
			network_info
			network_scan
			user
			interesting
			;;
		"exit")
			echo "${RED}Exiting enum script.${RESET}"
			break
			;;
		*)
			echo "${RED}Unknown command: '${command}'. Type 'help' for available commands.${RESET}"
			;;
	esac
	echo ""
done