#!/bin/bash

# Install packages
sudo apt-get update
sudo apt-get install -y nginx unzip

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

# Setup consul
cd /tmp
curl https://releases.hashicorp.com/consul/0.7.1/consul_0.7.1_linux_amd64.zip -o consul.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /var/consul
sudo mkdir -p /etc/consul/conf.d

cat >/tmp/config.json << EOF
{
  "data_dir": "/var/consul",
  "node_name": "${name}",
  "datacenter": "${environment}",
  "enable_syslog": true,
  "start_join": ["${consul_address}"],
  "encrypt": "${encryption_key}"
}
EOF

cat >/tmp/consul_flags << EOF
CONSUL_FLAGS="-config-dir=/etc/consul/conf.d"
EOF

cat >/tmp/consul.service << EOF
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target

[Service]
EnvironmentFile=-/etc/default/consul
Restart=on-failure
ExecStart=/usr/local/bin/consul agent $CONSUL_FLAGS
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/config.json /etc/consul/conf.d/config.json
sudo chown root:root /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service
sudo chmod 0644 /etc/systemd/system/consul.service
sudo mv /tmp/consul_flags /etc/default/consul
sudo chown root:root /etc/default/consul
sudo chmod 0644 /etc/default/consul
sudo systemctl enable consul.service
sudo systemctl start consul
