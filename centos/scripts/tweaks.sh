#!/bin/bash -eux

echo '==> Configuring sshd_config options'

echo '==> Turning off sshd DNS lookup to prevent timeout delay'
echo "UseDNS no" >> /etc/ssh/sshd_config

echo '==> Disablng GSSAPI authentication to prevent timeout delay'
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config

echo "==> Allow root login"
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config

echo "==> Install extra packages"
PACKAGES="bash-completion curl rsync sudo bzip2"
yum -y install $PACKAGES

if [ ! -z "$SSH_PUBLIC_KEY" ]; then
    echo '==> Installing provided SSH key for ' $SSH_PUBLIC_KEY
	mkdir -pm 700 /$SSH_USERNAME/.ssh
	echo "$SSH_PUBLIC_KEY" > /$SSH_USERNAME/.ssh/authorized_keys
	chown $SSH_USERNAME:$SSH_USERNAME /$SSH_USERNAME/.ssh -R
fi

if [ "$UNIQUE_HOST_SSH_KEY" = "true" ] || [ "$UNIQUE_HOST_SSH_KEY" = "1" ]; then
	echo "==> Force SSH Host key regenerate on first boot"
	rm -rfv /etc/ssh/*key*
fi

if [ "$PACKER_BUILDER_TYPE" = "qemu" ]; then
	echo "==> Enabling Libvirt console access"
	systemctl enable serial-getty@ttyS0.service
	systemctl start serial-getty@ttyS0.service
	sed -i 's/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb console=tty0 console=ttyS0"/' /etc/default/grub
	sed -i 's/GRUB_TERMINAL_OUTPUT="console"/GRUB_TERMINAL_OUTPUT="serial console"/' /etc/default/grub
	echo 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"' >> /etc/default/grub
	grub2-mkconfig --output=/boot/grub2/grub.cfg
fi