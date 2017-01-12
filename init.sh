#!/usr/bin/env bash

rm -fr `pwd`/auth
rm -fr `pwd`/certs
rm -fr `pwd`/data

mkdir -p `pwd`/auth
docker run --entrypoint htpasswd registry:2 -Bbn admin \
    "2secret" >> `pwd`/auth/htpasswd

mkdir -p `pwd`/certs
openssl req \
    -newkey rsa:4096 -nodes -sha256 \
    -x509 -days 356 \
    -keyout `pwd`/certs/registry-cert.key \
    -out `pwd`/certs/registry-cert.crt \
    -subj "/C=US/ST=Massachusetts/L=Boston/O=Continuul LLC/CN=continuul.io"

mkdir -p `pwd`/data
