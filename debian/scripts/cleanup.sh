#!/bin/bash -eux

# Store build time
date > /etc/image_build_time

DEBIAN_VERSION=$(lsb_release -sr)
if [[ ${DEBIAN_VERSION} == 9.0 ]]; then
    # When booting with Vagrant / VMware the PCI slot is changed from 33 to 32.
    # Instead of eth0 the interface is now called ens33 to mach the PCI slot,
    # so we need to change the networking scripts to enable the correct
    # interface.
    #
    # NOTE: After the machine is rebooted Packer will not be able to reconnect
    # (Vagrant will be able to) so make sure this is done in your final
    # provisioner.
    sed -i "s/ens33/ens32/g" /etc/network/interfaces
fi

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "==> Cleaning up leftover dhcp leases"
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi

echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Cleanup apt cache
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean

echo "==> Installed packages"
dpkg --get-selections | grep -v deinstall

DISK_USAGE_BEFORE_CLEANUP=$(df -h)

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/vagrant/.bash_history

# Clean up log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

echo "==> Clearing last login information"
>/var/log/lastlog
>/var/log/wtmp
>/var/log/btmp

if [[ $WHITEOUT  =~ true || $WHITEOUT =~ 1 || $WHITEOUT =~ yes ]]; then

	# Whiteout root
	count=$(df --sync -kP / | tail -n1  | awk -F ' ' '{print $4}')
	let count--
	dd if=/dev/zero of=/tmp/whitespace bs=1024 count=$count
	rm /tmp/whitespace

	# Whiteout /boot
	count=$(df --sync -kP /boot | tail -n1 | awk -F ' ' '{print $4}')
	let count--
	dd if=/dev/zero of=/boot/whitespace bs=1024 count=$count
	rm /boot/whitespace

	echo '==> Clear out swap and disable until reboot'
	set +e
	swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
	case "$?" in
	    2|0) ;;
	    *) exit 1 ;;
	esac
	set -e
	if [ "x${swapuuid}" != "x" ]; then
	    # Whiteout the swap partition to reduce box size
	    # Swap is disabled till reboot
	    swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
	    /sbin/swapoff "${swappart}"
	    dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
	    /sbin/mkswap -U "${swapuuid}" "${swappart}"
	fi

	# Zero out the free space to save space in the final image
	dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
	rm -f /EMPTY

fi

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early
sync

echo "==> Disk usage before cleanup"
echo ${DISK_USAGE_BEFORE_CLEANUP}

echo "==> Disk usage after cleanup"
df -h
