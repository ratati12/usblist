#!/bin/bash
apt install dialog -y
echo -en "Port 3232\n" >> ~/.ssh/config
clear

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE=""
TITLE="Welcome to remote PC manager"
MENU="Choose one of the following options:"

OPTIONS=(1 "Connect via SSH to remote host"
         2 "Configurate USBs on remote host")

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            HOST=$(whiptail --title "Connect via SSH to remote host" --inputbox "Enter ip:" 10 60  3>&1 1>&2 2>&3)

            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                ssh root@$HOST
            else
                exit 3
            fi
            ;;
        2)

            # ----- Choosing the disk -----
            LSBLK=$(lsblk -o NAME,SERIAL,MOUNTPOINTS,RM | grep 'sd[a-z]')
            DISK=$(whiptail --title "Choose the disk which you want to use:" --inputbox "$LSBLK\nPress ENTER if you want to create empty config\nChoice (for examle sdb): " 20 75 3>&1 1>&2 2>&3)
            exitstatus=$?
		    if [ $exitstatus != 0 ]; then
                exit 4
            fi
			clear
			# ----- Choosing the job -----
            SERIAL=$(udevadm info -a -p /sys/block/$DISK | grep 'ATTRS{serial}==\"[0-9A-Z]*[0-9A-Z]\"')
			
			echo '' > 99-usb.rules
            
            VAR=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$DISK Serial number = $SERIAL" \
                --menu "$MENU" \
                $HEIGHT 100 $CHOICE_HEIGHT \
                1 "Create new 99-usb.rules" \
                2 "Add a new serial in existed config on remote host" \
                3 "Remove config on remote host" \
                2>&1 >/dev/tty)
            

			# ----- Create new 99-usb.rules -----
			
			if ((VAR == 1)); then
				echo 'ENV{ID_USB_DRIVER}=="usb-storage",ENV{UDISKS_IGNORE}="1"' > ./99-usb.rules
				if [[ "$SERIAL" != '' ]]; then
					echo $SERIAL',ENV{UDISKS_IGNORE}="0"' >> ./99-usb.rules
				else
                    if (!(whiptail --title "$MENU" --yesno "Do you want to create empty config?" 10 60)); then
					exit 1
					fi
				fi
				if (whiptail --title "$MENU" --yesno "Do you want to spawn config on remote host?" 10 60); then
                    HOST=$(whiptail --inputbox "Enter remote host IP:" 10 60  3>&1 1>&2 2>&3)
					exitstatus=$?
                    if [ $exitstatus != 0 ]; then
                        exit 5
                    fi
                    scp ./99-usb.rules root@$HOST:/etc/udev/rules.d/
			        whiptail --msgbox "Config uploaded" 10 100; 
                    ssh root@$HOST "sudo udevadm control --reload-rules"	
					whiptail --msgbox "Reloaded udevadm control rules" 10 100;
			#	    systemctl -H root@$HOST --machine=user@.host --user stop gvfs-mtp-volume-monitor
			#	    echo -e "\033[1;40m[ ] Stop gvfc-mtp-volume-monitor\033[0m"	
			#        systemctl -H root@$HOST --machine=user@.host --user disable gvfs-mtp-volume-monitor
			#	    echo -e "\033[1;40m[ ] Disable gvfc-mtp-volume-monitor\033[0m"	
			#        systemctl -H root@$HOST --machine=user@.host --user mask gvfs-mtp-volume-monitor
			#	    echo -e "\033[1;40m[ ] Mask gvfc-mtp-volume-monitor\033[0m"	
			    fi
			fi
			
			# ----- Add a new serial in existed config on remote host -----
			
			if ((VAR == 2)); then
				if [[ "$SERIAL" == '' ]]; then
					clear
                    echo -e "\033[1mERROR: \033[1;41mNO SERIAL\033[0m"
					exit 2 
				fi
			    HOST=$(whiptail --inputbox "Enter remote host IP:" 10 60  3>&1 1>&2 2>&3)
				exitstatus=$?
                if [ $exitstatus != 0 ]; then
                    exit 5
                fi
                scp root@$HOST:/etc/udev/rules.d/99-usb.rules .
                TMP1=$(cat ./99-usb.rules)
				echo $SERIAL',ENV{UDISKS_IGNORE}="0"' >> ./99-usb.rules
                TMP2=$(cat ./99-usb.rules)
			    whiptail --title "Config on remote host:" --msgbox "Current config:\n$TMP1\n\nNew config:\n$TMP2" 30 100; 
			    if (whiptail --title "$MENU" --yesno "Upload?" 10 60); then
					scp ./99-usb.rules root@$HOST:/etc/udev/rules.d/
			        whiptail --msgbox "Config uploaded" 10 100; 
					ssh root@$HOST "sudo udevadm control --reload-rules"
					whiptail --msgbox "Reloaded udevadm control rules" 10 100;
			#        systemctl -H root@$HOST --machine=user@.host --user stop gvfs-mtp-volume-monitor
			#	    echo -e "\033[1;40m[ ] Stop gvfc-mtp-volume-monitor\033[0m"	
			#       systemctl -H root@$HOST --machine=user@.host --user disable gvfs-mtp-volume-monitor
			#	    echo -e "\033[1;40m[ ] Disable gvfc-mtp-volume-monitor\033[0m"	
			#       systemctl -H root@$HOST --machine=user@.host --user mask gvfs-mtp-volume-monitor
			#	    echo -e "\033[1;40m[ ] Mask gvfc-mtp-volume-monitor\033[0m"	
			    fi
			fi
			
			# ----- Remove config on remote host -----
			
			if ((VAR == 3)); then
			    HOST=$(whiptail --inputbox "Enter remote host IP:" 10 60  3>&1 1>&2 2>&3)
				exitstatus=$?
                if [ $exitstatus != 0 ]; then
                    exit 5
                fi	
			    ssh root@$HOST "rm /etc/udev/rules.d/99-usb.rules"
			    whiptail --msgbox "Config removed" 10 100; 
				ssh root@$HOST "sudo udevadm control --reload-rules"
			    whiptail --msgbox "Reloaded udevadm control rules" 10 100; 
			#   systemctl -H root@$HOST --machine=user@.host --user unmask gvfs-mtp-volume-monitor
			#	echo -e "\033[1;40m[ ] Unmask gvfc-mtp-volume-monitor\033[0m"	
			#   systemctl -H root@$HOST --machine=user@.host --user enable gvfs-mtp-volume-monitor
			#	echo -e "\033[1;40m[ ] Enable gvfc-mtp-volume-monitor\033[0m"	
			#   systemctl -H root@$HOST --machine=user@.host --user start gvfs-mtp-volume-monitor
			#	echo -e "\033[1;40m[ ] Start gvfc-mtp-volume-monitor\033[0m"	
			fi
			rm ~/.ssh/config
			;;
			esac
			exit 0
