#!/bin/bash

set -e

sudo /opt/puppetlabs/bin/puppet module install puppet-nginx
cat >/tmp/nginx.pp << "EOF"
class{'nginx': }
EOF
sleep 30
sudo /opt/puppetlabs/bin/puppet apply /tmp/nginx.pp
