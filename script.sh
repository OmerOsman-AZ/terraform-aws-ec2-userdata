#! /bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
echo "The page was created by the user data" | sudo tee /var/www/html/index.html