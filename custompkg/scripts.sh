#!/bin/bash
#
# Remove original-ks.cfg file
rm /root/original-ks.cfg
cat /root/custompkg/anaconda-ks.cfg > /root/anaconda-ks.cfg

# Add user and set password sysreport
sed -i 's/\:\$HOME\/bin//' /root/.bash_profile
sed -i 's/\:\$HOME\/\.local\/bin\:\$HOME\/bin//' /etc/skel/.bash_profile
useradd -G wheel sysreport
echo "Mfec@2012" | passwd --stdin sysreport

# Set NTP protocol with chrony service
sed -i 's/server/#server/' /etc/chrony.conf
echo "server 10.235.155.5 iburst prefer" >> /etc/chrony.conf
echo "server 10.232.95.5 iburst" >> /etc/chrony.conf

# Disable IPv6 all interface
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf

# Set hostname on this server
i=1;
for infoline in $(cat /root/custompkg/hostname.tls); do
    echo ${i}. $(echo ${infoline}|awk -F, '{print $1}');
    (( i++ ));
done

read -p "What is hostname on this server ? : " index

while [[ $index -lt 1 || $index -gt 22 ]]; do
    read -p "What is hostname on this server ? : " index
done

infoos=$(sed -n "${index} p" /root/custompkg/hostname.tls);
hname=$(echo ${infoos} | awk -F, '{print $1}')
hostnamectl set-hostname ${hname};

# Setup network interface
for iname in {eno1,eno2,eno3,eno4,ens2f0,ens2f1,ens3f0,ens3f1,ens4f0,ens4f1,ens5f0,ens5f1,ens6f0,ens6f1}; do
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-${iname}
TYPE=Ethernet
DEVICE=${iname}
NAME=${iname}
BOOTPROTO=none
ONBOOT=no
EOF
done

# Set OOB interface and static route
if [[ $index -eq 10 || $index -eq 20 ]]; then
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-ens5f1
TYPE=Ethernet
DEVICE=ens5f1
NAME=ens5f1
BOOTPROTO=none
ONBOOT=yes
IPADDR=$(echo ${infoos} | awk -F, '{print $2}')
PREFIX=24
EOF
cat << EOF > /etc/sysconfig/network-scripts/route-ens5f1
10.232.0.0/16 via 10.150.103.1 dev ens5f1
10.233.0.0/16 via 10.150.103.1 dev ens5f1
10.234.0.0/16 via 10.150.103.1 dev ens5f1
10.235.0.0/16 via 10.150.103.1 dev ens5f1
EOF
else
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eno4
TYPE=Ethernet
DEVICE=eno4
NAME=eno4
BOOTPROTO=none
ONBOOT=yes
IPADDR=$(echo ${infoos} | awk -F, '{print $2}')
PREFIX=24
EOF
cat << EOF > /etc/sysconfig/network-scripts/route-eno4
10.232.0.0/16 via 10.150.103.1 dev eno4
10.233.0.0/16 via 10.150.103.1 dev eno4
10.234.0.0/16 via 10.150.103.1 dev eno4
10.235.0.0/16 via 10.150.103.1 dev eno4
EOF
fi

# Create Bonding interface
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0
TYPE=bond
DEVICE=bond0
NAME=bond0
BOOTPROTO=none
ONBOOT=yes
BONDING_MASTER=yes
BONDING_OPTS="mode=4 miimon=100 lacp_rate=1"
EOF

# Create Slave interface
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-ens5f0
TYPE=Ethernet
DEVICE=ens5f0
NAME=ens5f0
BOOTPROTO=none
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-ens6f0
TYPE=Ethernet
DEVICE=ens6f0
NAME=ens6f0
BOOTPROTO=none
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF

# Create VLAN interface
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0.2004
TYPE=vlan
DEVICE=bond0.2004
BOOTPROTO=none
ONBOOT=yes
VLAN=yes
IPADDR=$(echo ${infoos} | awk -F, '{print $3}')
PREFIX=24
EOF

# Create VLAN interface
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0.3001
TYPE=vlan
DEVICE=bond0.3001
BOOTPROTO=none
ONBOOT=yes
VLAN=yes
IPADDR=$(echo ${infoos} | awk -F, '{print $4}')
PREFIX=24
GATEWAY=$(echo ${infoos} | awk -F, '{print $5}')
EOF

# Hardening fix
#chmod og-rwx /boot/grub2/grub.cfg
#chmod og-rwx /boot/efi/EFI/redhat/grub.cfg

cat << EOF >> /etc/audit/rules.d/audit.rules
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
EOF
pkill -HUP -P 1 auditd

#rm /etc/at.deny
touch /etc/at.allow
chown root:root /etc/at.allow
chmod og-rwx /etc/at.allow

mkdir -p /etc.d/dconf/db/gdm.d/
cat << EOF > /etc.d/dconf/db/gdm.d/01-banner-message
[org/gnome/login-screen] 

banner-message-enable=true 

banner-message-text= 

' This computer system is property of Advanced Info Service Public Company Limited (AIS) and must be accessed only by authorized users. Any unauthorized use of this system is strictly prohibited and deemed as violation to AIS'-s regulation on Information Technology and Computer System Security of Telecommunication and Wireless Business (Regulation). The unauthorized user or any person who breaches AIS'-s Regulation, policy, criteria and/or memorandums regarding IT Security will be punished by AIS and may be subject to criminal prosecution. All data contained within the systems is owned by AIS. The data may be monitored, intercepted, recorded, read, copied, or captured and disclosed in any manner by authorized personnel for prosecutions and other purposes according to AIS's Regulation. Any communication on or information stored within the system, including information stored locally on the hard drive or other media in use with this unit (e.g., floppy disks, PDAs and other hand-held peripherals, Handy drives, CD-ROMs, etc.), is also owned by AIS. AIS have all rights to  manage such information. Please contact IT Support if you encounter any computer problem.'
EOF

#chmod o-w /home/sysreport/*

# Remove all scripts
rm -f /root/custompkg/hostname.tls
rm -f /root/custompkg/hostname.sila
rm -f /root/custompkg/scripts.sh
rm -f /root/custompkg/anaconda-ks.cfg
