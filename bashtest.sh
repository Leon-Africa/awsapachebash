#!/bin/bash
#Leon Africa

#Installs apache on amazon linux
function al_apache () {

        sudo yum -y install httpd

        #Ensure permissions of webcontent can be launced by server
        sudo chown -R apache:apache /var/www/html

        #Ensure service starts automatically when server boots
        sudo chkconfig --levels 3 httpd on

        #start the server
        sudo service httpd start
}

#installs awscli on ubuntu server
function cli_ubuntu () {

        echo "Installing unzip..."
        sudo apt-get install unzip

        echo "Installing python..."
        sudo apt-get install python2.7

        echo "Installing aws cli..."
        sudo apt install awscli

        #curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
        #unzip awscli-bundle.zip
        #./awscli-bundle/install -b ~/bin/aws

        #echo "Exporting path to bin"
        #export PATH=~/bin:$PATH
        #alias aws=/home/ubuntu/bin/aws
        #echo "Created alias 'aws' for /home/ubuntu/bin/aws"
        #echo "You now have installed:"
        echo "You now have installed:"
        aws --version
}

#installs apache for ubuntu
function u_apache () {
        echo "Installing apache webserver..."
        sudo apt install apache2
        echo "Starting your webserver!"
        #start the server
        sudo service apache2 start
}

echo "Hello!"
echo "The following program creates a fully functional apache webserver ami"
echo -e "\n"


echo -n "Choose your instance type, for Amazon Linux enter A, for Ubuntu Server enter U  (A/U):"

read answer
if echo "$answer" | grep -iq "^a" ;then

        #Check that the user made the correct selection
        CHECK=$(which apt)
        if echo "$CHECK" | grep -iq "/usr/bin/apt" ; then
        echo "You are NOT running an amazon linux instance!"
        echo "Exiting the program...."
        exit 0
        fi

        echo -e "\n"
        echo "Amazon Linux comes with aws cli installed"
        echo "Updating your machine..."

        sudo yum update
        echo "you are currently running:"
        python --version
        echo "and"
        aws --version

        #install apache an amazon linux
        al_apache
        #set a variabe to note this installation
        TAKE="amazon"

elif echo "$answer" | grep -iq "^u" ; then

    #Check that the user made the correct selection
        CHECK=$(cat /etc/issue)
        if echo "$CHECK" | grep -iq "Amazon Linux" ; then
        echo "You are NOT running an Ubuntu Server instance!"
        echo "Exiting the program...."
        exit 0
        fi

        echo -e "\n"
        echo "Your Ubuntu Server instance requires configurations"
        echo "Updating your machine..."
        sudo apt-get update
        echo "Installing python..."
        sudo apt-get install python2.7
        echo "Installing aws cli..."
        cli_ubuntu
        u_apache
        #Set a variable to note this installation
        TAKE="ubuntu"
else
        echo "You have made an incorrect selection."
        echo "Exiting program!"
exit 0
fi

echo -e "\n"
echo "Please configure your aws-cli"
echo "NOTE: This program DOES NOT record your aws credentials"
echo -e "\n"
#configure aws cli
aws configure

if echo $TAKE | grep -iq 'amazon' ; then

        echo "Preparing ami creation!"

        echo "Retrieving your instance id..."
        EC2_INSTANCE_ID=$(ec2-metadata -i | awk -F" " '{print $2}')
        echo "Your instance-id is: ${EC2_INSTANCE_ID}"
        echo -e "\n"
        

        #Prompt for ami name taking into account that user might use spaces
        echo "Editing your security group..."
        #set http port open for securoty group to permit viewing webpage on server
        #get the group id for the insance and write to file
        aws ec2 describe-instances --instance-ids ${EC2_INSTANCE_ID} | grep -i "Groupid" | awk -F" " '{print $2}' | awk -F" " '{print $1}'> group.txt

        #grab the group id from the first line of the file
        line=$(head -n 1 group.txt)

        #Remove unwanted characters
        SID=$(echo "${line//'"'}")
        echo $SID
        #open inbound http port
        aws ec2 authorize-security-group-ingress --group-id ${SID} --protocol tcp --port 443 --cidr 0.0.0.0/0

        echo "Your webpage is now publicly viewable!"

        aws ec2 describe-instances --instance-ids ${EC2_INSTANCE_ID} | grep -i "PublicDnsName" | awk -F" " '{print $2}' | awk -F" " '{print $1}'> dns.txt

        #grab the group id from the first line of the file
        line=$(head -n 1 dns.txt)

        #Remove unwanted characters
        EDIT=$(echo ${line//'"'})
        DNS=$(echo ${EDIT//','})


        echo -e "\n"

        echo "Creating an ami for instance with id ${EC2_INSTANCE_ID}"
        echo -e "\n"

        echo "NOTE: when entreing a name DO NOT ENTER SPACE, for example 'my webserver' must be entered as one word 'mywebserver'"

        echo -e "/n"

        read -p "Enter a name for your ami, ie myami, NO SPACES BETWEEN WORDS!: " name
        
        #no spaces allowed in name
        #if[[$name=~.* .* ]] then
        NAME=$(echo "$description" | sed -e s/" "/"-"/)
        #fi

        NAME=$name

        read -p "Enter a name for your ami, ie myami, NO SPACES BETWEEN WORDS!:" description
        
        #no spaces allowed in description
        #if[[$description=~.* .* ]] then
        DESCRIPTION=$(echo "$description" | sed -e s/" "/"-"/)
        #fi
        #DESCRIPTION=$description


        

        #create the ami
        aws ec2 create-image --instance-id ${EC2_INSTANCE_ID} --name ${NAME} --description ${DESCRIPTION}

        echo "Successfully created ami!"
        echo "You may now view the ami in your aws console."
        echo "Rebooting your instance!"

        echo -e "\n"
        
        echo "Copy this url in your browser to VIEW YOUR WEBPAGE:"

        echo -e "\n"

        echo $DNS

        echo -e "\n"
        echo "Your webpage is now publicly viewable!"

elif echo $TAKE | grep -iq 'ubuntu' ; then
        echo "Preparing ami creation!"

        echo "Installing cloud utils..."
        sudo apt-get install cloud-utils
        echo "Retrieving your instance id...."
        EC2_INSTANCE_ID=$(ec2metadata --instance-id)
        echo "Your instance-id is: ${EC2_INSTANCE_ID}"
        echo -e "\n"


        #Prompt for ami name taking into account that user might use spaces
        echo "Editing your security group..."
        #set http port open for securoty group to permit viewing webpage on server
        #get the group id for the insance and write to file
        aws ec2 describe-instances --instance-ids ${EC2_INSTANCE_ID} | grep -i "Groupid" | awk -F" " '{print $2}' | awk -F" " '{print $1}'> group.txt

        #grab the group id from the first line of the file
        line=$(head -n 1 group.txt)

        #Remove unwanted characters
        SID=$(echo ${line//'"'})
        echo $SID
        #open inbound http port
        aws ec2 authorize-security-group-ingress --group-id ${SID} --protocol tcp --port 443 --cidr 0.0.0.0/0

        echo "Your webpage is now publicly viewable!"
        #Get Public DNS
        aws ec2 describe-instances --instance-ids ${EC2_INSTANCE_ID} | grep -i "PublicDnsName" | awk -F" " '{print $2}' | awk -F" " '{print $1}'> dns.txt

        #grab the group id from the first line of the file
        line=$(head -n 1 dns.txt)

        #Remove unwanted characters
        EDIT=$(echo ${line//'"'})
        DNS=$(echo ${EDIT//','})

        echo -e "\n"

        echo "Creating an ami for instance with id ${EC2_INSTANCE_ID}"
        echo -e "\n"

        echo "NOTE: when entreing a name DO NOT ENTER SPACE, for example 'my webserver' must be entered as one word 'mywebserver'"

        read -p "Enter a name for your ami, ie myami, NO SPACES BETWEEN WORDS!:" name

        if[[$name=~.* .* ]] then
        NAME=$(echo "$name" | sed -e s/" "/"-"/)
        fi
      
         #NAME=$name

        read -p "Enter a description for your ami, ie apachewebsever, NO SPACES BETWEEN WORDS!:" description


        if[[$description=~.* .* ]] then
        #echo "Description containing spaces are not accepted!"
        #echo "Program will now exit."
         DESCRIPTION=$(echo "$description" | sed -e s/" "/"-"/)
       
        fi

        #DESCRIPTION=$description

        #create the ami
        aws ec2 create-image --instance-id ${EC2_INSTANCE_ID} --name ${NAME} --description ${DESCRIPTION}

        echo "Successfully created ami!"
        echo "You may now view the ami in your aws console."
        echo "Rebooting your instance!"

        echo -e "\n"
        
        echo "Copy this url in your browser to VIEW YOUR WEBPAGE:"

        echo -e "\n"

        echo $DNS

        echo -e "\n"

        echo "Your webpage is now publicly viewable!"

else
        echo "error"
fi


