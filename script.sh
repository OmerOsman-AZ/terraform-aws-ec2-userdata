#! /bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
echo "The page was created by the user data" | sudo tee /var/www/html/index.html

# Create a directoy 
sudo mkdir -p /opt/copiedfiles/
#sudo chown -R root:omer /opt/copiedfiles/  (root is the owner and Omer is the group)
sudo chmod -R 755 /opt/copiedfiles/ #  Read, write, and execute permissions to the owner of the file

# install python 3.8 neeed by the aws cli installation
sudo amazon-linux-extras install python3.8
#sudo amazon-linux-extras install python3.8=3.8.10-1.amzn2.0.1 -y

# install the aws cli
pip3 install awscli --upgrade --user
#curl "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-macos.zip" -o "awscliv.zip"
#unzip awscliv.zip
#sudo ./aws/install
aws --version

# copy sample file from s3 bucket to the directory created above
echo -e "\n copy sample file from s3 bucket"
sudo /usr/bin/aws s3 cp s3://filestobecopiedtoec2instance/touploadtos3samplefile.txt /opt/copiedfiles/



# update the text file
if [[ -f "/opt/copiedfiles/touploadtos3samplefile.txt" ]]; then
    # create a backup of original file "touploadtos3samplefile.txt" before making changes
    echo -e "\n creating a backup of the original file"
    sudo cp /opt/copiedfiles/touploadtos3samplefile.txt /opt/copiedfiles/touploadtos3samplefilebackup.txt
    echo -e "\n updating the touploadtos3samplefile file and create anther backup to test .bak option"
	sed -i.bak 's/testing/validating/g' /opt/copiedfiles/touploadtos3samplefile.txt
fi



