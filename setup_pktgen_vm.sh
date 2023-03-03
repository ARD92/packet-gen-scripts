sudo apt-get -y update; sudo apt-get -y install qemu-kvm libvirt-bin ubuntu-vm-builder br
idge-utils virt-manager
apt-get install -y net-tools tcpdump wget sshpass
https://linuxhint.com/libvirt_python/
apt install libguestfs-tools
mkdir -p /root/ubuntu-image
cd ubuntu-image
wget https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-
amd64.img
for s in pktgen1 pktgen2; do
cp /root/ubuntu-image/ubuntu-20.04-server-cloudimg-amd64.img /home/aprabh/pktgen_images/$
s.qcow2
done
for s in pktgen1 pktgen2; do
qemu-img resize /home/aprabh/pktgen_images/$s.qcow2 +50G
done
mkdir -p /root/ubuntu-vm-bringup
for i in $(seq 1 2); do
cat > /root/ubuntu-vm-bringup/pktgen$i-mgmt-interfaces.yaml <<EOF
network:
  ethernets:
    ens3:
      addresses: [192.168.123.$i/24]
      gateway4: 192.168.122.1
      dhcp4: no
      nameservers:
        addresses: [10.85.6.68]
      optional: true
    ens4:
      addresses:
        - 172.17.122.$i/24
        - 2001:db9:122::$i/64
      dhcp4: no
      nameservers:
        addresses: [10.85.6.68]
      optional: true
  version: 2
EOF
done

#########
## For 2 servers
for s in pktgen1 pktgen2; do
virt-customize -a /home/aprabh/pktgen_images/$s.qcow2 \
--root-password password:Embe1mpls \
--hostname $s \
--run-command 'sed -i "s/.*PasswordAuthentication no/PasswordAuthentication yes/g" /etc/s
sh/sshd_config' \
--run-command 'sed -i "s/.*PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/
ssh/sshd_config' \
--upload /root/ubuntu-vm-bringup/$s-mgmt-interfaces.yaml:/etc/netplan/interfaces.yaml \
--run-command 'dpkg-reconfigure openssh-server' \
--run-command 'sed -i "s/GRUB_CMDLINE_LINUX=\"\(.*\)\"/GRUB_CMDLINE_LINUX=\"\1 net.ifname
s=1 biosdevname=0\"/" /etc/default/grub' \
--run-command 'update-grub' \
--run-command 'apt-get purge -y cloud-init'
done


#Define bridge
##############

declare -A routerlink=( [pktgen1]="pktgen-data1 pktgen-data2"
	       		[pktgen2]="pktgen-data1 pktgen-data2")

for r in "${!routerlink[@]}"; do
    for b in ${routerlink[$r]}; do
        if [[ -z $(virsh net-list |grep "$b ") ]]; then
cat > /tmp/$b.xml <<EOF
<network><name>$b</name><bridge name='$b' stp='off' delay='0'/></network>
EOF
virsh net-define /tmp/$b.xml
virsh net-start $b
virsh net-autostart $b
rm -f /tmp/$b.xml
        fi
    done
done

#>> Define and start Ubuntu server
##################################
for s in pktgen1 pktgen2; do
virt-install --name $s \
--disk /home/aprabh/pktgen_images/$s.qcow2,size=50,format=qcow2 \
--vcpus 4 \
--cpu host-model \
--memory 4096 \
--network network=default,target=$s-ens3 \
--network network=pktgen-data1,target=$s-ens4 \
--virt-type kvm \
--import \
--os-variant=${OS} \
--graphics vnc \
--serial pty \
--noautoconsole \
--console pty,target_type=virtio
done
