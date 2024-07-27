#!/bin/bash
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
sudo tee /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<body style="background-color:blue;">

<h1>VERSION-1.0.0</h1>

</body>
</html>
EOF