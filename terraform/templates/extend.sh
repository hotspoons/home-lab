#!/bin/bash

 

vol_extend_logfile='/home/ec2-user/vol_extend.log'

 

echo "begin vol_extend..." &>> $vol_extend_logfile

VOLUME=/dev/nvme0n1

growpart $VOLUME 3  &>> $vol_extend_logfile  #(partition number, 3 is the one with everything else under it)

pvresize "${VOLUME}p3" &>> $vol_extend_logfile

lvm lvextend -l +25%FREE /dev/mapper/vg00-opt &>> $vol_extend_logfile

lvm lvextend -l +50%FREE /dev/mapper/vg00-var  &>> $vol_extend_logfile

lvm lvextend -l +100%FREE /dev/mapper/vg00-home &>> $vol_extend_logfile

xfs_growfs -d /opt &>> $vol_extend_logfile

xfs_growfs -d /var &>> $vol_extend_logfile

xfs_growfs -d /home &>> $vol_extend_logfile

 

 

echo "Vol Extend finished." &>> $vol_extend_logfile
