#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: gerald.venzl@oracle.com
# Description: Installs Oracle database software
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

echo 'INSTALLER: Started up'
ORACLE_CHARACTERSET=AL32UTF8
# get up to date
yum upgrade -y
yum clean all
echo 'INSTALLER: System updated'


# fix locale warning
yum reinstall -y glibc-common
echo LANG=en_US.UTF-8 >> /etc/environment
echo LC_ALL=en_US.UTF-8 >> /etc/environment

echo 'INSTALLER: Locale set'

yum install -y bc oracle-rdbms-server-11gR2-preinstall openssl gcc gcc-c++ unzip zip git
echo 'INSTALLER: Oracle preinstall and openssl complete'

sudo mkdir -p $ORACLE_BASE && \
sudo chown oracle:oinstall -R $ORACLE_BASE && \
#sudo mkdir /u01/app/
#ln -s $ORACLE_BASE /u01/app/oracle

echo 'INSTALLER: Oracle directories created'

# set environment variables
sudo echo "export ORACLE_BASE=/u01/app/oracle" >> /home/oracle/.bashrc && \
sudo echo "export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/db_1" >> /home/oracle/.bashrc && \
sudo echo "export ORACLE_SID=orcl11g" >> /home/oracle/.bashrc   && \
sudo echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

# install Oracle
#unzip /vagrant/V28748-01.zip p10404530_112030_Linux-x86-64_1of7.zip p10404530_112030_Linux-x86-64_2of7.zip -d /vagrant ;\
unzip /vagrant/p13390677_112040_Linux-x86-64_1of7.zip -d /vagrant && unzip /vagrant/p13390677_112040_Linux-x86-64_2of7.zip -d /vagrant ;\
#rm -rf /vagrant/Disk1 && \
sudo ln -s /u01/app/oracle /opt/oracle

echo 'INSTALLER: Oracle installation software uncompressed'

cp /vagrant/ora-response/db_install.rsp.tmpl /vagrant/ora-response/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /vagrant/ora-response/db_install.rsp && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /vagrant/ora-response/db_install.rsp && \
sed -i -e "s|###ORACLE_EDITION###|$ORACLE_EDITION|g" /vagrant/ora-response/db_install.rsp
sudo su -l oracle -c "yes | /vagrant/database/runInstaller -silent -showProgress -ignorePrereq -waitforcompletion -responseFile /vagrant/ora-response/db_install.rsp"
sudo $ORACLE_BASE/oraInventory/orainstRoot.sh
sudo $ORACLE_HOME/root.sh
rm -rf /vagrant/database
rm /vagrant/ora-response/db_install.rsp

echo 'INSTALLER: Oracle software installed'


## Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -hex 8`"}
cp /vagrant/ora-response/dbca.rsp.tmpl /vagrant/ora-response/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /vagrant/ora-response/dbca.rsp && \
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /vagrant/ora-response/dbca.rsp && \
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /vagrant/ora-response/dbca.rsp
sudo su -l oracle -c "dbca -silent -createDatabase -responseFile /vagrant/ora-response/dbca.rsp"
rm /vagrant/ora-response/dbca.rsp

echo 'INSTALLER: Database created'


# set environment variables
#sudo echo "export ORACLE_BASE=/u01/app/oracle" >> /home/oracle/.bashrc && \
#sudo echo "export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/db_1" >> /home/oracle/.bashrc && \
#sudo echo "export ORACLE_SID=orcl11g" >> /home/oracle/.bashrc   && \
#sudo echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

cp /vagrant/scripts/setPassword.sh /home/oracle/ && \
chmod a+rx /home/oracle/setPassword.sh
#
echo "INSTALLER: setPassword.sh file setup";
#
echo "ORACLE PASSWORD FOR SYS AND SYSTEM: $ORACLE_PWD";
#
echo "INSTALLER: Installation complete, database ready to use!";
#
echo "Copying dbora to /etc/init.d"
#
cp /vagrant/scripts/dbora /vagrant/scripts/dbora.tmp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /vagrant/scripts/dbora.tmp
cp /vagrant/scripts/dbora.tmp /etc/init.d/dbora
rm /vagrant/scripts/dbora.tmp
#
echo "Changing permissions and ownership for /etc/init.d/dbora"
#
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /etc/init.d/dbora
#
chmod 750 /etc/init.d/dbora
chown root:root /etc/init.d/dbora
#
echo "enabling database autostart"
#
chkconfig --add dbora
chkconfig dbora on
#
echo "database dbora autostart set"
#

