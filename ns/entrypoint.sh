#!/bin/sh

cd /etc/bind

mkdir -p managed-keys primary secondary
chown -R named:named .

named -c /etc/bind/named.conf -4 -g -u named
