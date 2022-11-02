#!/bin/bash
clear
echo -e "\033[1;34m"
echo "Choose the disk which you want to use:"
echo -e "\033[0m"
lsblk -o NAME,SERIAL,MOUNTPOINTS,RM | grep 'sd[a-z]'

echo -e "Press \033[30;47mENTER\033[0m if you want to create empty config"
echo -e "\033[1;34m"
read -p "Choice (for examle sdb): " DISK
echo -e "\033[0m"

clear
SERIAL=$(udevadm info -a -p /sys/block/$DISK | grep 'ATTRS{serial}==\"[0-9A-Z]*[0-9A-Z]\"')
if [[ "$SERIAL" != '' ]]; then
	echo -e "\033[1;42m$DISK Serial number ="$SERIAL"\033[0m"
else
	echo -e "\033[1;41mSerial number ="$SERIAL"\033[0m"
fi
touch 99-usb.rules
echo -e "Choose \033[1;5;44m1/2\033[0m :\n1. Create new 99-usb.rules\n2. Add a new serial in existed config on remote host"
read VAR


if ((VAR == 1)); then
	echo 'ENV{ID_USB_DRIVER}=="usb-storage",ENV{UDISKS_IGNORE}="1"' > ./99-usb.rules
	if [[ "$SERIAL" != '' ]]; then
		echo $SERIAL',ENV{UDISKS_IGNORE}="0"' >> ./99-usb.rules
	else
		echo -e "\033[1;33mDo you want to create empty config? \033[0m\033[1;5;44myes/no\033[0m"
		read VAR
		if [[ "$VAR" == "no" ]]; then
		exit 1
		fi
	fi
	
	echo -e "\033[1;33mDo you want to spawn config on remote host? \033[0m\033[1;5;44myes/no\033[0m"
	read VAR
	if [[ "$VAR" == "yes" ]]; then
		echo 'Enter remote host IP:'
		echo -e "\033[1;32m"	
		read -p "Remote host IP = " HOST
		echo -e "\033[0m"
		scp -P 3232 ./99-usb.rules root@$HOST:/etc/udev/rules.d/
		echo -e "\033[1;40m[ ] Config uploaded\033[0m"
		ssh -p 3232 root@$HOST "sudo udevadm control --reload-rules"	
		echo -e "\033[1;40m[ ] Reloaded udevadm control rules\033[0m"	
	fi
fi
if ((VAR == 2)); then
	if [[ "$SERIAL" == '' ]]; then
		echo -e "\033[1mERROR: \033[1;41mNO SERIAL\033[0m"
		exit 2 
	fi
	echo 'Enter remote host IP:'
	echo -e "\033[1;32m"	
	read -p "Remote host IP = " HOST
	echo -e "\033[0m"
	scp -P 3232 root@$HOST:/etc/udev/rules.d/99-usb.rules .	
	echo -e "\n\033[1;40m[ ] Current config on remote host:\033[0m"
	cat ./99-usb.rules
	echo -e "\n\n"	
	echo $SERIAL',ENV{UDISKS_IGNORE}="0"' >> ./99-usb.rules
	echo -e "\n\033[1;40m[ ] New config:\033[0m"
	cat ./99-usb.rules
	echo -e "\033[1;33mUpload? \033[0m\033[1;5;44myes/no\033[0m"
	read VAR
	if [[ "$VAR" == "yes" ]]; then
		scp -P 3232 ./99-usb.rules root@$HOST:/etc/udev/rules.d/
		echo -e "\033[1;40m[ ] Config uploaded\033[0m"
		ssh -p 3232 root@$HOST "sudo udevadm control --reload-rules"
		echo -e "\033[1;40m[ ] Reloaded udevadm control rules\033[0m"	
	fi
fi
exit 0
