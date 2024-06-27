#! /bin/bash


# bash -x ./install.sh IlebApp UAT ileb-appadmin

RawTargetPackages=$1
TargetPackages=$(echo $RawTargetPackages | tr , " " )
Environment=$2
S3_location=$3
host_name=`hostname`


echo "Started copying middleware artifacts at" $(date) >> /opt/out.txt
echo "Install the Packages" $RawTargetPackages >> /opt/out.txt
echo "Install the TargetPackages"$(echo $RawTargetPackages | tr , " " )
echo "Install from the S3_location" $S3_location >> /opt/out.txt
echo "Install the Artifacts for the host_name" $host_name >> /opt/out.txt
echo "Installing for the Environment" $Environment >> /opt/out.txt


sudo sed -i "s/#log_path/log_path/" /etc/ansible/ansible.cfg
sudo touch /var/log/ansible.log
sudo chown appadmin:appadmin /var/log/ansible.log

#create required directory structure
sudo mkdir -p /opt/middleware/{autostart,java,newhost,properties,tmp,tomcat,$ENV,$TargetPackage}
sudo chown -R appadmin:appadmin /opt/middleware/
sudo chmod -R 755 /opt/middleware/

#staging the required middleware components from the remote s3 location

sudo /usr/local/bin/aws s3 cp s3://${S3_location}/properties/autostart /opt/middleware/autostart --recursive
sudo /usr/local/bin/aws s3 cp s3://${S3_location}/properties/tmp /opt/middleware/tmp --recursive
sudo /usr/local/bin/aws s3 cp s3://${S3_location}/properties/update-hostname.sh /opt/middleware/tmp/

#update  permissions and owner of the files
sudo chown -R appadmin:appadmin /opt/middleware
sudo chmod -R 755 /opt/middleware/

#set password for appadmin
sudo dos2unix /opt/middleware/tmp/*
echo "appadmin:$(/opt/middleware/tmp/tmp $HOSTNAME)" | sudo chpasswd


#Install Middleware and Update configuration files
        for TargetPackage in $TargetPackages; do
		
			 #install middleware component

				sudo /usr/local/bin/aws s3 cp s3://${S3_location}/$TargetPackage/$Environment/config/${TargetPackage}.app.yml /opt/middleware/$Environment/config/${TargetPackage}.app.yml
				sudo chmod -R 755 /opt/middleware/

				eval application=$(grep EnvName /opt/middleware/$Environment/config/$TargetPackage.app.yml |  awk '{ print $2 }' )

				if [[ -f "/opt/middleware/$Environment/config/${TargetPackage}.app.yml" ]]; then

					#sudo mkdir -p /u01/app/appadmin/product/apache_tomcat
					
					#sudo mkdir -p /u01/app/appadmin/product/java/openjdk

					#sudo chown -R appadmin:appadmin /u01/app/appadmin/product/*

					#sudo /usr/local/bin/aws s3 cp s3://${S3_location}/$TargetPackage/java /opt/middleware/$TargetPackage/java --recursive

					#sudo /usr/local/bin/aws s3 cp s3://${S3_location}/$TargetPackage/tomcat /opt/middleware/$TargetPackage/tomcat --recursive

					sudo /usr/local/bin/aws s3 cp s3://${S3_location}/$TargetPackage/$Environment/config /opt/middleware/$TargetPackage/$Environment/config --recursive

					sudo mv /opt/middleware/${TargetPackage}/$Environment/config/appconfig/*.env /u01/app/appadmin/env/
					
					#Update Mounts
					if [[ -f "/opt/middleware/${TargetPackage}/$Environment/config/serverconfig/mount.sh" ]]; then
						echo -e "\n Setting up Mount for" $TargetPackage "at" $(date) >> /opt/out.txt
						dos2unix /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/mount.sh
						chmod +x /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/mount.sh
						sudo /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/mount.sh
						sudo rm /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/mount.sh
					fi

					#tar -xvf /opt/middleware/$TargetPackage/java/*.tar.gz --directory /u01/app/appadmin/product/java/openjdk/

					#tar -xvzf /opt/middleware/$TargetPackage/tomcat/*.tar.gz --directory /u01/app/appadmin/product/apache_tomcat/

					cp -r /u01/app/appadmin/product/apache_tomcat/apache-tomcat-* /u01/app/appadmin/product/apache_tomcat/$application

					echo -e "\n Middleware components installed successfully for" $TargetPackage "at" $(date) >> /opt/out.txt

					# Installing/updating application specific configuration files

					sudo mkdir -p /u01/maximus/${application}/{logs,scripts,webapps,deploy,custom_conf/app_config/config,bin}

					sudo chmod -R 2755 /u01/maximus/${application}/scripts/

					sudo chmod 2755 /u01/maximus/ /u01/app/

					sudo chown -R appadmin:appadmin /u01/maximus/ /u01/app/

					rm -rf /u01/app/appadmin/product/apache_tomcat/${application}/{logs,webapps}

					ln -s /u01/maximus/${application}/logs /u01/app/appadmin/product/apache_tomcat/${application}/logs

					ln -s /u01/maximus/${application}/webapps /u01/app/appadmin/product/apache_tomcat/${application}/webapps
					
					if [[ -f "/opt/middleware/${TargetPackage}/$Environment/config/serverconfig/config.sh" ]]; then
						sudo -u appadmin dos2unix /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/config.sh
						sudo -u appadmin sh /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/config.sh ${application}
						sudo rm /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/config.sh
					fi

					sudo mv /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/{catalina.properties,server.xml,context.xml} /u01/app/appadmin/product/apache_tomcat/${application}/conf/

					sudo mv /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/{startservices,stopservices,bounceservices,setenv.sh} /u01/app/appadmin/product/apache_tomcat/${application}/bin/

					sudo mv /opt/middleware/${TargetPackage}/$Environment/config/serverconfig/{contrast*,datasource-*,jdbc.jar,ojdbc.jar} /u01/app/appadmin/product/apache_tomcat/${application}/lib/

					dos2unix /u01/app/appadmin/product/apache_tomcat/${application}/bin/{startservices,stopservices,bounceservices,setenv.sh}

					dos2unix /u01/app/appadmin/product/apache_tomcat/${application}/conf/{catalina.properties,context.xml,server.xml}

					sudo chmod +x /u01/app/appadmin/product/apache_tomcat/${application}/bin/{startservices,stopservices,bounceservices,setenv.sh}

					sudo mv /opt/middleware/${TargetPackage}/$Environment/config/appconfig/${application}.env /u01/app/appadmin/env/

					sudo chmod 644 /u01/app/appadmin/env/${application}.env

					sudo -u appadmin dos2unix /u01/app/appadmin/env/${application}.env

					#Update configuration files

					if [[ -d "/opt/middleware/${TargetPackage}/$Environment/config/appconfig" ]]; then
							sudo cp -r /opt/middleware/${TargetPackage}/$Environment/config/appconfig/* /u01/maximus/${application}/custom_conf/app_config/
							#cd /u01/maximus/${application}/custom_conf/app_config/
					fi
					
					if [[ -f "/u01/maximus/${application}/custom_conf/app_config/ehcache.xml" ]]; then
						ipaddress=$(hostname -i)
						sed -ie "s/localhost/$ipaddress/g" /u01/maximus/$application/custom_conf/app_config/ehcache.xml
						rm /u01/maximus/$application/custom_conf/app_config/ehcache.xmle
					fi

					if [[ -f "/u01/app/appadmin/scripts/purgecfg.txt" ]]; then
							sed --in-place /${application}/d /u01/app/appadmin/scripts/purgecfg.txt
							printf "/u01/maximus/${application}/logs/" >> /u01/app/appadmin/scripts/purgecfg.txt
							printf '\n' >> /u01/app/appadmin/scripts/purgecfg.txt
					fi

					# sudo -u appadmin chmod +x /u01/maximus/${application}/scripts/*_startstop.sh
					# sudo -u appadmin dos2unix /u01/maximus/${application}/scripts/*_startstop.sh
					echo -e "\t End of Configuration files updated at" $(date) >> /opt/out.txt
				fi
				
				#Deploy and Update Snapshots files
				# grab the snapshots
				versions=$(/usr/local/bin/aws s3 ls s3://${S3_location}/${TargetPackage}/$Environment/snapshots/ | egrep -v : | awk '{ print $2 }')
				max=0
				maxDir=""
				for v in $versions; do

					firstvar=$(echo ${v} | cut -d/ -f1 | cut -d. -f1)
					firstmvar=$(( 1000000000000*$firstvar ))
					
					# #grab the second numerical value from the snapshot directory name
					# secondvar=$(echo ${v} | cut -d/ -f2 | cut -d. -f2)
					# secondmvar=$(( 100000000*$secondvar ))

					# #grab the third numerical value from the snapshot directory name
					# thirdvar=$(echo ${v} | cut -d/ -f2 | cut -d. -f3)
					# thirdmvar=$(( 10000*$thirdvar ))

					# #grab the fourth numerical value from the snapshot directory name
					# fourthmvar=$(echo ${v} | cut -d/ -f3 | sed 's%/%%g')
					
					#current=$(( $firstmvar + $secondmvar + $thirdmvar + $fourthmvar ))
					current=$firstmvar
					
					if (( ${current} > ${max} )); then
						max=$current
						maxDir=$v
					fi
				done		
				#$maxDir should contain the name of the latest snapshot

				#Deploy war files
				wardir=$(/usr/local/bin/aws s3 ls s3://${S3_location}/${TargetPackage}/$Environment/snapshots/${maxDir} | egrep -e 'war|tgz' | awk '{ print $4 }')
				echo -e "\n\t Deploy war/tgz  files from "${wardir}" with latest snapshot "${maxDir} "at" $(date) >> /opt/out.txt
				case $wardir in
					*.war)
						if [[ ! -f "/u01/maximus/${application}/webapps/${wardir}" ]]; then
							sudo /usr/local/bin/aws s3 cp s3://${S3_location}/${TargetPackage}/$Environment/snapshots/${maxDir%?}/${wardir} /u01/maximus/${application}/webapps/
							echo -e "\n\t Deployed war files from "${wardir}" with latest snapshot "${maxDir} "at" $(date) " to /u01/maximus/${application}/webapps/ " >> /opt/out.txt
						else
							echo -e "\n\t war file already exists, Skipped war file deployment at" $(date) >> /opt/out.txt
						fi
					;;
				esac
				
				echo -e "================================================================================================================================="  >> /opt/out.txt
				echo -e "================================================================================================================================="  >> /opt/out.txt
								
		done


#Resize /u01 size
resizeu01=$(lsblk | grep /u01 | awk '{ print $1 }')
sudo resize2fs /dev/${resizeu01}

#update Application ownership
sudo chown -R appadmin:appadmin /u01/maximus
sudo chown -R appadmin:appadmin /u01/app/appadmin

#restart the applications after the war files are deployed
sudo -u appadmin service mmsappctl restart

echo -e " started updating the hostname for reporting to splunkforwarder at" $(date) >> /opt/out.txt
sudo /opt/middleware/tmp/update-hostname.sh
echo -e " Updated the hostname for reporting to splunkforwarder and restarted splunk Forwarder at" $(date) >> /opt/out.txt

echo -e " Successfully configured all the required application and server configurations and is now ready for validation at" $(date) >> /opt/out.txt
cat /opt/out.txt > /var/log/app_install.log
sudo chown appadmin:appadmin /var/log/app_install.log

#removing the staging directories after the successful installation
sudo rm -rf /opt/middleware /opt/install*.sh /opt/logansible.txt /opt/temp.log /opt/out.txt /u01/app/appadmin/product/apache_tomcat/apache-tomcat-*
