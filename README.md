# Setting Up a Private Docker Registry for Private Kubernetes Clusters

At Continuul, by creating database as a service capabilities
for Kubernetes, we provide a new class of database as a service,
known as database as a microservice, allowing databases to now
benefit from all the features of microservices that applications
have had.

We iteratively develop our features in the same way application
developers do, and to test these customer-driven features we need
to test against a valid Kubernetes environment, ipso facto, we need
a private registry to test our Docker images.

This article details how we create private registries that our
Kubernetes test clusters use to pull images from. Writing this
article proved beneficial to me as well, to learn how this all
works; as an organization we need to not only be able to speak to
business value, but also be technically astute, both in terms of
breadth and depth.

We hope you, too, have time to follow along and try this out,
that this information proves beneficial.

## Prerequisites

At Continuul we do all testing within Linux VMs run on VMWare.
If you're following along, the Docker Registry is run within
a Docker VM, as is MiniKube.

It is left as an exercise to the reader if they so choose to
use VirtualBox instead.

We use, and highly recommend testing with VMWare instead.

## Security Options

There are two security options, the first uses HTPASSWD,
and the second uses self-signed certificates. Choose from
among these options and continue below.

### Setting Up HTPASSWD Security

The next step to get this registry up and running is to
create our username and password. We need to create some
credentials and a directory to store them. This will set
up minimum security recommended by docker registry.

Use the registry:2 Docker image to create a Bcrypt encoded
password for each user needing access to your repository. 

```bash
mkdir -p `pwd`/auth
docker run --entrypoint htpasswd registry:2 -Bbn admin \
    "2secret" >> `pwd`/auth/htpasswd
```

### Setting Up Self-Signed Certificates

Create a directory for your self-signed SSL certificate
and private key. Then create the certificates, copying
them into these directories:

First, create our directories:

```bash
mkdir -p `pwd`/certs
```

First generate a private key and CSR:

```bash
openssl req \
    -newkey rsa:4096 -nodes -sha256 \
    -x509 -days 356 \
    -keyout `pwd`/certs/registry-cert.key \
    -out `pwd`/certs/registry-cert.crt
```

Answer the required information, or add the subject information
non-interactively such as:

```bash
openssl req \
    -newkey rsa:4096 -nodes -sha256 \
    -x509 -days 356 \
    -keyout `pwd`/certs/registry-cert.key \
    -out `pwd`/certs/registry-cert.crt \
    -subj "/C=US/ST=Massachusetts/L=Boston/O=Continuul LLC/CN=continuul.io"
```

### Setting Up Paid Certificates

This is left as a highly recommended todo for the reader.

### Create a Storage Directory for the Registry

We need to create local storage for the registry images:

```bash
mkdir -p `pwd`/data
```

### Run the Docker Registry

To run the Docker Registry with the ACLs provided and certificates,
run the following command:

```bash
docker run -d -p 5000:5000 --restart=always --name registry \
    -v `pwd`/auth:/auth \
    -v `pwd`/certs:/certs \
    -v `pwd`/data:/data \
    -e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry-cert.crt" \
    -e "REGISTRY_HTTP_TLS_KEY=/certs/registry-cert.key" \
    -e "REGISTRY_AUTH=htpasswd" \
    -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
    -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
    registry:2
```

The corresponding docker-compose.yml file is:

```yaml

```

If you're using docker-compose, simply:

```bash
docker-compose up -d
```

### Test the Registry

Now lets test our registry by logging into it using our admin
user and password:

```bash
$ docker login localhost:5000
Username: admin
Password: *******
Login Succeeded
```

Or more simply:

```bash
docker login -u admin -p "2secret" localhost:5000
```

Note that the login credentials are stored in your Docker JSON config
file:

```bash
cat ~/.docker/config.json
```

You will need to login in order to perform push/pull operations.

## Push an Image

At Continuul, our web site is actually deployed as a Docker image.
We ourselves benefit from all the features of microservices, and in
particular, of blue-green environments, by having the ability to
roll forward, or back, our web site, and to fully test it. As a test
we will push our Docker web site image to this registry.

```bash
cd www.continuul.io
make
```

You need to tag your image correctly first, though, with your
registry host:

> docker tag [OPTIONS] IMAGE[:TAG] [REGISTRYHOST/][USERNAME/]NAME[:TAG]

Then docker push using that same tag.

> docker push NAME[:TAG]

For example, following along with our website:

```bash
...
docker tag continuul/site:latest localhost:5000/continuul/site:0.1
docker images
docker push localhost:5000/continuul/site:0.1
```

Now lets list the Docker images on the registry:

```bash

```

So before we actually test in Kubernetes, lets test locally in Docker
to make sure we can pull from the registry:

```bash
docker pull localhost:5000/continuul/site:latest
docker images
```

Verify you have the image installed. If you have, you're now ready
to move onto integrating with Kubernetes.

## Next

# Citations

The following we articles proved helpful to me in learning
about this:

- [Using a private Docker Registry with Kubernetes](https://blog.cloudhelix.io/using-a-private-docker-registry-with-kubernetes-f8d5f6b8f646#.mn7gps9t1), CloudHelix, Nov 25, 2016, James Leavers
- [Insecure And Self-Signed Private Docker Registry With Boot2Docker](https://coderwall.com/p/dtwc1q/insecure-and-self-signed-private-docker-registry-with-boot2docker), Lendesk Technologies, Nov 22, 2016, Ivan Sim
- [OpenSSL Essentials: Working with SSL Certificates, Private Keys and CSRs](https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs), DigitalOcean, Sep 12, 2014, Mitchell Anicas 
