#!/bin/bash

ADMIN_USER=$1
ADMIN_PASS=$2

sudo -u $ADMIN_USER sh -c "echo StrictHostKeyChecking no > /home/$ADMIN_USER/.ssh/config"

sudo -u $ADMIN_USER ssh-keygen -f /home/$ADMIN_USER/.ssh/id_rsa -t rsa -N ''

for h in az-es-mgs az-es-mds0 az-es-mds1 az-es-mds2 az-es-mds3 az-es-oss0 az-es-oss1 az-es-oss2 az-es-oss3; do
	sudo -u $ADMIN_USER sh -c "sshpass -p $ADMIN_PASS ssh-copy-id ${h}"
done

sudo -u $ADMIN_USER clush -w az-es-mgs,az-es-mds[0-3],az-es-oss[0-3] "sshpass -p $ADMIN_PASS sudo sh -c \"echo $ADMIN_PASS | passwd --stdin root\""

for h in az-es-mgs az-es-mds0 az-es-mds1 az-es-oss0 az-es-mds2 az-es-mds3 az-es-oss1 az-es-oss2 az-es-oss3; do
	sudo -u $ADMIN_USER sh -c "sshpass -p $ADMIN_PASS ssh-copy-id root@${h}"
done

sudo -u $ADMIN_USER ssh root@az-es-mgs mkfs.lustre --mgs --fsname=lustre /dev/sdc
sudo -u $ADMIN_USER ssh root@az-es-mgs mkdir -p /mnt/lustre/mgs
sudo -u $ADMIN_USER ssh root@az-es-mgs mount -t lustre /dev/sdc /mnt/lustre/mgs

for i in `seq 0 3`; do
	sudo -u $ADMIN_USER ssh root@az-es-mds${i} mkfs.lustre --mdt --mgsnode=az-es-mgs --index=${i} --fsname=lustre /dev/sdc
	sudo -u $ADMIN_USER ssh root@az-es-mds${i} mkdir -p /mnt/lustre/mdt${i}
	sudo -u $ADMIN_USER ssh root@az-es-mds${i} mount -t lustre /dev/sdc /mnt/lustre/mdt${i}
done

for i in `seq 0 3`; do
	sudo -u $ADMIN_USER ssh root@az-es-oss${i} mkfs.lustre --ost --mgsnode=az-es-mgs --index=${i} --fsname=lustre /dev/sdc
	sudo -u $ADMIN_USER ssh root@az-es-oss${i} mkdir -p /mnt/lustre/ost${i}
	sudo -u $ADMIN_USER ssh root@az-es-oss${i} mount -t lustre /dev/sdc /mnt/lustre/ost${i}
done
