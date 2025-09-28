yum update -y
yum install -y httpd
echo "Hello from $(hostname -f)" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
