#!/bin/bash -eux

echo "==> Only allow root login with key"
sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

echo '==> Turning off sshd DNS lookup to prevent timeout delay'
echo "UseDNS no" >> /etc/ssh/sshd_config

echo '==> Disablng GSSAPI authentication to prevent timeout delay'
sed -i 's/#GSSAPIAuthentication no/GSSAPIAuthentication no/' /etc/ssh/sshd_config

echo "==> Only allow SSH login with public key (disable password logins)"
sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/' /etc/ssh/sshd_config

# Verwijder referentie naar 127.0.1.1 uit hosts
sed -i '/127.0.1.1/d' /etc/hosts

PACKAGES="bzip2 curl rsync sudo python zsh"
apt-get install -y --no-install-recommends $PACKAGES

if [ ! -z "$SSH_PUBLIC_KEY" ]; then
    echo '==> Installing provided SSH key for ' $SSH_PUBLIC_KEY
	mkdir -pm 700 /$SSH_USERNAME/.ssh
	echo "$SSH_PUBLIC_KEY" > /$SSH_USERNAME/.ssh/authorized_keys
	chown $SSH_USERNAME:$SSH_USERNAME /$SSH_USERNAME/.ssh -R
fi

if [ "$UNIQUE_HOST_SSH_KEY" = "true" ] || [ "$UNIQUE_HOST_SSH_KEY" = "1" ]; then
	echo "==> Force SSH Host key regenerate on first boot"
	rm -rfv /etc/ssh/*key*
	sed -i 's/.*exit.*/test -f \/etc\/ssh\/ssh_host_dsa_key || dpkg-reconfigure openssh-server\n\n&/' /etc/rc.local
fi

if [ "$PACKER_BUILDER_TYPE" = "qemu" ]; then
	echo "==> Enabling Libvirt console access"
	cp /etc/init/tty1.conf /etc/init/ttyS0.conf
	sed -i 's/# tty1 - getty/# ttyS0 - getty/' /etc/init/ttyS0.conf
	sed -i 's/exec \/sbin\/getty -8 38400 tty1/exec \/sbin\/getty -8 115200 ttyS0 xterm/' /etc/init/ttyS0.conf
	sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0"/' /etc/default/grub
	sed -i 's/#GRUB_TERMINAL=console/GRUB_TERMINAL="serial console"/' /etc/default/grub
	echo 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"' >> /etc/default/grub
	/usr/sbin/update-grub
fi