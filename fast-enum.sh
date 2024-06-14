#!/bin/sh

RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

echo "\n"

echo "${RED}[*] OS / System Information${RESET}"
echo "${YELLOW}OS:${RESET} $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)"
echo "${YELLOW}OS Version:${RESET} $(grep '^VERSION=' /etc/os-release | cut -d '"' -f 2)"
echo "Linux Kernel: $(dmesg | grep 'Linux version' | cut -d ' ' -f 8)"
echo "Hostname: $(hostname)"

echo "\n"

echo "${RED}[*] Network Information${RESET}"
ip a | awk '/^[0-9]+:/ { iface=$2; sub(/:/, "", iface); } /^[[:space:]]*inet / { sub(/\/[0-9]+$/, "", $2); print "Interface:", iface, $2; }'
echo "DNS Nameserver: $(cat /etc/resolv.conf | grep nameserver | cut -d ' ' -f 2)"

echo "\n"

echo "${RED}[*] Current User Information${RESET}"
echo "Current User: $(whoami)"
echo "ID: $(id | cut -d " " -f 1-2)"
echo "Groups: $(groups)"
if [ "$(id -u)" -eq 0 ]; then
    echo "Sudo Privileges: $(sudo -l | sed '1d; 2d; 3d')"
fi

echo "\n"

echo "${RED}[*] User Enumeration${RESET}"
echo "Listing all users with shell!\n"
for user in $(awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh|\/bin\/ksh|\/bin\/zsh|\/usr\/bin\/fish)$/ {print $1}' /etc/passwd); do
	groups=$(groups $user | cut -d ":" -f 2)
	if [ "$(id -u)" -eq 0 ]; then
		hash=$(awk -v user="$user" -F: '($1 == user) {print $2}' /etc/shadow 2>/dev/null)
		echo "User: $user Password Hash: $hash Groups:$groups"
	else
		echo "User: $user Groups:$groups"
	fi
done

echo "\n"
