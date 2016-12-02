#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx

# Added index.html
sudo cat >/var/www/html/index.html << "EOF"
<html>
  <head>
    <title>Web service</title>
  </head>
  <body>
    <h1>Empatic.Org placeholder</h1>
  </body>
</html>
EOF

sudo service nginx start
