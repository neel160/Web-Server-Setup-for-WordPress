#! /usr/bin/env bash

#Warning: Script requires host file to read ip address username and password
#Place the file in the directory of the script
#Format: IP address,username,password

#requires sshpass

#generating ssh key

ssh-keygen -t rsa
echo "Enter package name.."
read packagename
	
while read ip username password;
do
	sshpass -p "$password" ssh-copy-id -i ~/.ssh/sshkey.pub $username@$password;
done < host

while read ip username password;
do
	ssh $username@$ip pacman -S $package
done < host

