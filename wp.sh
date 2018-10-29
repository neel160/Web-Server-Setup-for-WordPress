
#! /bin/bash

#Author: Neelam Verma


dearchive() {
	echo "${green} [*]De-archiving wordpress..${reset}"
	unzip -j /var/www/$domain/wordpress.zip -d /var/www/$domain/
	echo "${green} [*]Wordpress extracted successfully ${reset}"
	echo "${logdate} Extraction completed succesffully." >> $log
}


#Script requires root privileges
if [ $(id -u) -ne 0 ]; then
	echo "Script requires root privileges. Please run as root.." 1>&2
	exit 1
fi

#tput specs
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

#Create log.
sudo touch /tmp/wp.log
log=/tmp/wp.log

echo "${green}Log created${reset}"
logdate=`date`

#Check for installed applications
echo "Querying list of programs required for this operation"

if [ "$(dpkg-query -l|grep -i -c "ngnix")" -ge 0 ]; then
	echo "${green} [*] Nginx found.${reset}"
	echo "${logdate} Ngnix found" >> $log
else
	echo "${green}*Installing nginx${reset}"
	sudo apt-get install -y nginx
	echo "${logdate} Nginx installed" >> $log
fi

if [ "$(dpkg-query -l|grep -i -c "mysql")" -ge 0 ]; then
	echo "${green} [*] Mysql found.${reset}"
	echo "${logdate} Mysql found" >> $log
else
	echo "${green}*Installing mysql${reset}"
	sudo apt-get install -y mysql
	echo "${logdate} Mysql installed" >> $log
fi

if [ "$(dpkg-query -l|grep -i -c "php")" -ge 0 ]; then
	echo "${green} [*] PHP found.${reset}"
	echo "${logdate} PHP found" >> $log
else
	echo "${green}*Installing PHP${reset}"
	sudo apt-get install php
	echo "${logdate} PHP installed." >> $log
fi

#Read domain name from the user

echo "${green} [*] Enter the domain name ...${reset}"
read domain
if [ -z $domain ]; then
       while [ -z $domain ] 
       do
          echo "${red} Please enter valid domain${reset}"
          read domain  
       done
fi

echo "Domain  :: $domain" >> $log

#Add domain entry to /etc/hosts

host=/etc/hosts
if [ -f $host ]; then
	sed -i "\$a127.0.0.1\t${domain}" $host
	echo "${green} Entry for domain created succesffully ${reset}"
	echo "${logdate} Entry for ${domain} created succesfully at /etc/hosts" >> $log
else
	echo "${red} Cannot find hosts file ${reset}"
	echo "${logate}[Err] Cannot find hosts file" >> $log
	exit 1
fi
	
#Create nginx configuration file
#Backup

nginx_default=/etc/nginx/sites-available/default
nginx_enabled=/etc/nginx/sites-enabled/$domain
#Copy as backup to tmp
sudo cp $nginx_default /tmp/default
sudo cp $nginx_default $nginx_enabled
#Define necessary changes
#Add index.php for php support
sed -i 's/index index.html index.htm index.nginx-debian.html\;/index index.html index.php index.htm index.nginx-debian.html\;/g' $nginx_enabled
sed -i "s/server_name example.com/server_name $domain/g" $nginx_enabled
sed -i "85{s/root/#/}" $nginx_enabled
sed -i "86iroot /var/www/$domain\;" $nginx_enabled
#Uncomment necessary lines
sed -i "56,61{s/#//}" $nginx_enabled 
sed -i "63{s/#//}" $nginx_enabled
sed -i "68,70{s/#//}" $nginx_enabled 
sed -i "79,92{s/#//}" $nginx_enabled 

#Hide the default config which is running at port 80 and enable our config

sudo mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/.default
echo "${green} Backup created successfully ${reset}"
echo "${logdate} Domain file copied successfully to sites-enabled" >> $log
sed -i "s/www.example.com/$domain/g" $nginx_enabled
echo "${green} [*]File configuration created successfully${reset}"
#Test the config
if [ "$(sudo nginx -t|grep -i -c "failed")" -ge 1 ]; then
	echo "${red} Nginx configuration failed ${reset}"
	echo "${logdate}[Err] Nginx configuration failed..." >> $log
else
	echo "${green} [*] Nginx configuration test success!${reset}"
	echo "${logdate} Nginx test success" >> $log
fi

#Downlod wordpress

echo "${green} [*]Preparing to download the latest version of wordpress ${reset}"
echo "${logdate} Downloading latest version of Wordpress" >> $log

curl -L http://wordpress.org/latest.zip -o wordpress.zip 

sudo mkdir /var/www/$domain
echo "${logdate} Moving wordpress to /var/www/$domain" >> $log
sudo mv wordpress.zip /var/www/$domain/ 
echo "${logdate} File moved successfully to /var/www/$domain" >> $log
if [ "$(dpkg-query -l|grep "unzip")" -ge 1 ]; then 
	dearchive	
else
	echo "${red} Unzip not installed ${reset}";
	echo "${green} Installing unzip ${reset}";
	sudo apt-get install unzip
	dearchive
fi

#Create database
postfix="_db"
dbname=$domain$postfix
echo $dbname
echo "${green} [-p] Enter root password ${reset}"
stty -echo
read  dbpass
stty echo
mysql -u root -p$dbpass <<EOF
CREATE DATABASE IF NOT EXISTS \`$dbname\` CHARACTER SET utf8 COLLATE utf8_general_ci
EOF
if [ $? -ne 0 ]; then
	echo "${red} Cannot access mysql ${reset}"
	echo "${logdate}[Err] Cannot access mysql" >> $log 
	exit 1
else
	echo "${green} [*] Database created successfully"
	echo "${logdate} Database created :: $dbname" >> $log
fi


#Create config file

config_path=/var/www/$domain/

#Copy file
sudo cp $config_path/wp-config-sample.php $config_path/wp-config.php
echo "${logdate} File copied successfully" >> $log

if [ -f $config_path/wp-config.php ] 
then
	sed -i "s/database_name_here/$dbname/g" $config_path/wp-config.php
	sed -i "s/username_here/root/g" $config_path/wp-config.php
	sed -i "s/password_here/$dbpass/g" $config_path/wp-config.php
	echo "${green} [*] Config generated successfully. ${reset}"
	echo "${logdate} wp-config generated succesfully. ${reset}" >> $log
else
	echo "${red} [!] Cannot generate config${reset}"
	echo "${logdate}[Err] Couldn't generate wordpress configuration" >> $log
fi

#Fix permissions
sudo chmod 644 /var/www/$domain/wp-config.php
#remove zip file
#sudo rm -r /var/www/$domain/wordpress.zip
echo "${green} [*] Cleaning up.${reset}"
echo "${logdate} Cleanup completed successfully" >> $log
#Restart nginx 
sudo service nginx restart
echo "${green} [*] Restarting server.${reset}"
echo "${logdate} Nginx restarted." >> $log
echo "${green} [*] Done ${reset}"

