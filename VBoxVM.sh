#!/bin/bash

# Copyright (C) 2018 Markus Uhlin. All rights reserved.
#
# Create a virtual machine with VirtualBox.
#
# Requires: Oracle VM VirtualBox Extension Pack
# ---------------------------------------------
#
# Install the extension pack with the SAME version as your installed
# version of VirtualBox, for example:
# 	cd /tmp
# 	wget https://download.virtualbox.org/virtualbox/5.1.38/
# 	    Oracle_VM_VirtualBox_Extension_Pack-5.1.38.vbox-extpack
# 	VBoxManage extpack install
# 	    Oracle_VM_VirtualBox_Extension_Pack-5.1.38.vbox-extpack

CPUS=2
VRDEPORT=13389

fatal () {
    echo "fatal error"
    exit 1
}

echo "------------------------------"
echo "This program creates a VBox VM"
echo "------------------------------"
echo ""
echo "Minimal validation of user input is done."
echo "So be sure of the input you pass to this program."
echo ""

if test ! -f "$(which VBoxManage)"; then
    echo "fatal: VBoxManage not found"
    exit 1
fi

read -p 'VM name: ' name
read -p 'OS type (Execute: VBoxManage list ostypes): ' ostype
read -p 'HD size in MB: ' size
read -p 'DVD medium (ISO with the operating system): ' medium
read -p 'RAM Memory in MB: ' mem
read -p 'Username: ' user
read -p 'RDP password: ' -s pass

echo ""

if test -z "$name"\
	-o -z "$ostype"\
	-o -z "$size"\
	-o -z "$medium"\
	-o -z "$mem"\
	-o -z "$user"\
	-o -z "$pass"; then
    echo "fatal: empty input"
    exit 1
fi

if test ! -f "$medium"; then
    echo "fatal: medium not found"
    exit 1
fi

VBoxManage createvm --name "$name" --ostype "$ostype" --register || fatal

VBoxManage createhd\
	--filename "${name}.vdi"\
	--size "$size"\
	--format VDI\
	--variant Fixed || fatal

VBoxManage storagectl "$name" --name sata_ctl --add sata || fatal
VBoxManage storageattach "$name"\
	--storagectl sata_ctl\
	--port 0 --device 0\
	--type dvddrive\
	--medium "$medium" || fatal
VBoxManage storageattach "$name"\
	--storagectl sata_ctl\
	--port 1 --device 0\
	--type hdd\
	--medium "${name}.vdi" || fatal

VBoxManage modifyvm "$name"\
	--boot1 dvd --boot2 disk --boot3 none --boot4 none\
	--cpus "$CPUS"\
	--memory "$mem"\
	--vram 128\
	--vrdeauthtype external\
	--vrdeextpack "Oracle VM VirtualBox Extension Pack" || fatal

VBoxManage setproperty vrdeauthlibrary "VBoxAuthSimple"
pw_hash=$(VBoxManage internalcommands passwordhash "$pass" | awk '{ print $3 }')
VBoxManage setextradata "$name" "VBoxAuthSimple/users/$user" "$pw_hash"

VBoxManage modifyvm "$name" --vrde on --vrdeport "$VRDEPORT"

echo ""
echo "[32mdone[0m"
echo "start the vm by using the VBoxHeadless command"
echo "VRDEPORT = $VRDEPORT"
echo "connect to it using rdesktop (after starting the vm)"
echo ""
