#!/usr/bin/env bash

set -exo pipefail

dnf upgrade --refresh -y && dnf install -y pgrep vim httpd curl openssl liboqs oqsprovider crypto-policies-scripts tcpdump sed mod_ssl restorecon

update-crypto-policies --set DEFAULT:TEST-PQ

sed -i '/default = default_sect/a oqsprovider = oqs_sect' /etc/pki/tls/openssl.cnf

sed -i '/activate = 1/ {
a [oqs_sect]
a activate = 1
}' /etc/pki/tls/openssl.cnf

#OpenSSL key and certificates generation

openssl ecparam -out p256.pem -name P-256

openssl req -x509 -newkey ec:p256.pem -keyout root.key -out root.crt -subj /CN=localhost -batch -nodes -days 36500 -sha256

#apache configuration

cp root.crt /etc/pki/tls/certs/localhost.crt
cp root.key /etc/pki/tls/private/localhost.key

restorecon /etc/pki/tls/private/localhost.key
restorecon /etc/pki/tls/certs/localhost.crt

chown root:root /etc/pki/tls/private/localhost.key
chown root:root /etc/pki/tls/certs/localhost.crt

chmod 0600 /etc/pki/tls/private/localhost.key
chmod 0600 /etc/pki/tls/certs/localhost.crt

sed -i '1i ServerName localhost' /etc/httpd/conf/httpd.conf
