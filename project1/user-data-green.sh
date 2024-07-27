#!/bin/bash
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
sudo tee /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<body style="background-color:green;">

<h1>VERSION-2.0.0</h1>

</body>
</html>
EOF
         