#!/bin/sh

#!/bin/bash -ux

case "$PACKER_BUILDER_TYPE" in

virtualbox-iso|virtualbox-ovf)
    echo "==> Installing VirtualBox guest additions"
    apt-get install -y linux-headers-$(uname -r) build-essential perl
    apt-get install -y dkms

    VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
    mount -o loop /home/vagrant/VBoxGuestAdditions_${VBOX_VERSION}.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
    rm /home/vagrant/VBoxGuestAdditions_${VBOX_VERSION}.iso
    rm /home/vagrant/.vbox_version

    if [[ $VBOX_VERSION = "4.3.10" ]]; then
        ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
    fi
    ;;

vmware-iso|vmware-vmx)
    if [ "${VMWARE_TOOLS_TYPE}" == "distro" ]; then
        echo "==> Installing Open VM Tools"
        apt-get install open-vm-tools -y
    else
        echo "==> Installing VMware Tools"
        apt-get install -y linux-headers-$(uname -r) build-essential perl

        cd /tmp
        mkdir -p /mnt/cdrom
        mount -o loop $VMWARE_TOOLS_LOCATION /mnt/cdrom

        VMWARE_TOOLS_PATH=$(ls /mnt/cdrom/VMwareTools-*.tar.gz)
        VMWARE_TOOLS_VERSION=$(echo "${VMWARE_TOOLS_PATH}" | cut -f2 -d'-')
        VMWARE_TOOLS_BUILD=$(echo "${VMWARE_TOOLS_PATH}" | cut -f3 -d'-')
        VMWARE_TOOLS_BUILD=$(basename ${VMWARE_TOOLS_BUILD} .tar.gz)
        echo "==> VMware Tools Path: ${VMWARE_TOOLS_PATH}"
        echo "==> VMware Tools Version: ${VMWARE_TOOLS_VERSION}"
        echo "==> VMWare Tools Build: ${VMWARE_TOOLS_BUILD}"

        tar zxf /mnt/cdrom/VMwareTools-*.tar.gz -C /tmp/
        VMWARE_TOOLS_MAJOR_VERSION=$(echo ${VMWARE_TOOLS_VERSION} | cut -d '.' -f 1)
        if [ "${VMWARE_TOOLS_MAJOR_VERSION}" -lt "10" ]; then
            /tmp/vmware-tools-distrib/vmware-install.pl -d
        else
            /tmp/vmware-tools-distrib/vmware-install.pl --force-install
        fi

        rm $VMWARE_TOOLS_LOCATION
        umount /mnt/cdrom
        rmdir /mnt/cdrom
        rm -rf /tmp/VMwareTools-*
    fi
    ;;

*)
    echo "Unknown Packer Builder Type >>$PACKER_BUILDER_TYPE<< selected."
    echo "Known are virtualbox-iso|virtualbox-ovf|vmware-iso|vmware-vmx."
    ;;

esac