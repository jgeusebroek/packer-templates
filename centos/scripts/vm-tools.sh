#!/bin/sh

#!/bin/bash -ux

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

case "$PACKER_BUILDER_TYPE" in

virtualbox-iso|virtualbox-ovf)
    echo "==> Installing VirtualBox guest additions"
    # Assume that we've installed all the prerequisites:
    # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    # from the install media via ks.cfg

    VBOX_VERSION=$(cat $SSH_USER_HOME/.vbox_version)
    mount -o loop $SSH_USER_HOME/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
    rm -rf $SSH_USER_HOME/VBoxGuestAdditions_$VBOX_VERSION.iso
    rm -f $SSH_USER_HOME/.vbox_version

    if [[ $VBOX_VERSION = "4.3.10" ]]; then
        ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
    fi

    echo "==> Removing packages needed for building guest tools"
    yum -y remove gcc cpp libmpc mpfr kernel-devel kernel-headers perl
    ;;

vmware-iso|vmware-vmx)

    if [ "${VMWARE_TOOLS_TYPE}" == "distro" ]; then
        echo "==> Installing Open VM Tools"
        yum -y install open-vm-tools
    else
        echo "==> Installing VMware Tools"
        yum -y install kernel-headers kernel-devel gcc make perl curl wget bzip2 dkms patch net-tools git sudo nfs-utils

        cat /etc/redhat-release
        if grep -q -i "release 6" /etc/redhat-release ; then
            # Uninstall fuse to fake out the vmware install so it won't try to
            # enable the VMware blocking filesystem
            yum erase -y fuse
        fi
        # Assume that we've installed all the prerequisites:
        # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
        # from the install media via ks.cfg

        # On RHEL 5, add /sbin to PATH because vagrant does a probe for
        # vmhgfs with lsmod sans PATH
        if grep -q -i "release 5" /etc/redhat-release ; then
            echo "export PATH=$PATH:/usr/sbin:/sbin" >> $SSH_USER_HOME/.bashrc
        fi

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