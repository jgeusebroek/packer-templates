# Packer templates

These are my packer templates for building Debian, CentOS and Ubuntu boxes. It is heavily based on the awesome [Boxcutter](https://github.com/boxcutter) project, however tweaked quite a bit for my specific usage.

The main difference is that it also provides templates for building for VMWare ESXi (vSphere) and KVM environments.

# Usage

Edit the provided var files (not the main) build, your liking. Change passwords, public key's etc. This is similar to boxcutter.
Keep in mind *any* of the variables used in the main build config, can be overrided when using a `var-file`.

Run a build like so:

`$ packer build -var-file=debian-8.json debian-vagrant.json`

To limit a vagrant build to only virtualbox or vmware, use the `-limit=virtualbox-iso` or `-limit=vmware-iso` option when building.

**Note**: The vagrant builds have the mandatory vagrant user configured, however vSphere and KVM builds do not have a user configured. There is only a `root` user with the default password `toor`. You have the responsibility to harden it on the first provision. The first thing you should do is create a user with sudo ability and disable ssh root login and change the password.

## vSphere

Firstly `cp environment.sh.dist environment.sh && chmod 700 environment.sh` and fill in the variables.
Before running packer, run `environment.sh` to set the necessary variables.

`$ packer build -var-file=debian-8.json debian-vsphere.json`

You can find the resulting build in the builds directory on the datastore you set in the `enviroment.sh`.

## Qemu

`$ packer build -var-file=debian-8.json debian-qemu.json`

Access to the console is available with libvirt.

## Public Vagrant Atlas boxes

The vagrant boxes build by these templates are publicly available:

[jgeusebroek/debian-7](https://atlas.hashicorp.com/jgeusebroek/boxes/debian-7) |
[jgeusebroek/debian-8](https://atlas.hashicorp.com/jgeusebroek/boxes/debian-8) |
[jgeusebroek/centos-7](https://atlas.hashicorp.com/jgeusebroek/boxes/centos-7) |
[jgeusebroek/ubuntu-1404](https://atlas.hashicorp.com/jgeusebroek/boxes/ubuntu-1404)

I try to keep them up-to-date, but best to update using the distribution package tool.

Example usage:

	$ mkdir project && cd project
	$ vagrant init jgeusebroek/debian-8
	$ vagrant up

## License

MIT / BSD

## Author

[Jeroen Geusebroek](http://jeroengeusebroek.nl/)