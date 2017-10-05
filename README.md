# This fork

Differs to the original in that it automates the "dns-01" challenge using the Cloudflare API. (revert to using the original's "http-01" challenge using [simp_le](https://github.com/kuba/simp_le) with `CHALLENGE_SCRIPT=simp_le` in your `docker-compose.yml`)

It uses [dehydrated](https://github.com/lukas2511/dehydrated) and the [Cloudflare hook](https://github.com/kappataumu/letsencrypt-cloudflare-hook).

## Required variables

Required in `docker-compose.yml`:

 - `CF_EMAIL`
 - `CF_KEY`

### Optional variables

`ACME_CA_URI=https://acme-staging.api.letsencrypt.org/directory`

But then also obtain the fake root with:

    curl -s https://acme-staging.api.letsencrypt.org/acme/issuer-cert | \
        openssl x509 -inform der -outform pem -out FakeLERootX1.pem

...then import and "always trust" `FakeLERootX1.pem` in your key manager. **I recommend this for short-term testing purposes, otherwise you might run into Evil Hacker's fake root and get compromised.**


## Example

Go to the Cloudflare DNS settings for your domain (`opyate.com` in my case), and add an A record named `whoami.dev` with IP `0.0.0.0` with the traffic NOT going through Cloudflare (click the little cloud icon to make it grey).

```yaml
version: "2"
services:

  whoami:
    image: jwilder/whoami
    container_name: whoami
    environment:
      VIRTUAL_HOST: whoami.dev.opyate.com
      LETSENCRYPT_HOST: whoami.dev.opyate.com
      LETSENCRYPT_EMAIL: opyate@gmail.com
    networks:
      - intranet
  # https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion
  www:
    image: jwilder/nginx-proxy
    ports:
      - "443:443"
      - "80:80"
    networks:
      - intranet
    volumes:
      - ./certs:/etc/nginx/certs:ro
      - /etc/nginx/vhost.d
      - /usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro
    # The label is needed so that the letsencrypt container
    # knows which nginx proxy container to use.
    labels:
      - "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true"

  wwwcompanion:
    # image: jrcs/letsencrypt-nginx-proxy-companion
    build: docker-letsencrypt-nginx-proxy-companion
    volumes:
      - ./certs:/etc/nginx/certs:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
    volumes_from:
      - www
    networks:
      - intranet
    environment:
      CF_EMAIL: opyate@gmail.com
      CF_KEY: 7b1d5a387463e0ced69d6254fcf423620ccee
      ACME_CA_URI: https://acme-staging.api.letsencrypt.org/directory

networks:
  intranet:
    driver: bridge

```

`docker-compose up` and go to `https://whoami.dev.opyate.com` and see something like "I'm 3b25e58c55b9".

# Original

[![](https://images.microbadger.com/badges/version/jrcs/letsencrypt-nginx-proxy-companion.svg)](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion "Click to view the image on Docker Hub")
[![](https://images.microbadger.com/badges/image/jrcs/letsencrypt-nginx-proxy-companion.svg)](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion "Click to view the image on Docker Hub")
[![](https://img.shields.io/docker/stars/jrcs/letsencrypt-nginx-proxy-companion.svg)](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion "Click to view the image on Docker Hub")
[![](https://img.shields.io/docker/pulls/jrcs/letsencrypt-nginx-proxy-companion.svg)](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion "Click to view the image on Docker Hub")

letsencrypt-nginx-proxy-companion is a lightweight companion container for the [nginx-proxy](https://github.com/jwilder/nginx-proxy). It allows the creation/renewal of Let's Encrypt certificates automatically. See [Let's Encrypt section](#lets-encrypt) for configuration details.

### Features:
* Automatic creation/renewal of Let's Encrypt certificates using original nginx-proxy container.
* Support creation of Multi-Domain ([SAN](https://www.digicert.com/subject-alternative-name.htm)) Certificates.
* Automatically creation of a Strong Diffie-Hellman Group (for having an A+ Rate on the [Qualsys SSL Server Test](https://www.ssllabs.com/ssltest/)).
* Work with all versions of docker.

***NOTE***: The first time this container is launched it generates a new Diffie-Hellman group file. This process can take several minutes to complete (be patient).

#### Usage

To use it with original [nginx-proxy](https://github.com/jwilder/nginx-proxy) container you must declare 3 writable volumes from the [nginx-proxy](https://github.com/jwilder/nginx-proxy) container:
* `/etc/nginx/certs` to create/renew Let's Encrypt certificates
* `/etc/nginx/vhost.d` to change the configuration of vhosts (needed by Let's Encrypt)
* `/usr/share/nginx/html` to write challenge files.

Example of use:

* First start nginx with the 3 volumes declared:
```bash
$ docker run -d -p 80:80 -p 443:443 \
    --name nginx-proxy \
    -v /path/to/certs:/etc/nginx/certs:ro \
    -v /etc/nginx/vhost.d \
    -v /usr/share/nginx/html \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
    jwilder/nginx-proxy
```
The "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy" label is needed so that the letsencrypt container knows which nginx proxy container to use.

* Second start this container:
```bash
$ docker run -d \
    -v /path/to/certs:/etc/nginx/certs:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    --volumes-from nginx-proxy \
    jrcs/letsencrypt-nginx-proxy-companion
```

Then start any containers you want proxied with a env var `VIRTUAL_HOST=subdomain.youdomain.com`

    $ docker run -e "VIRTUAL_HOST=foo.bar.com" ...

The containers being proxied must [expose](https://docs.docker.com/reference/run/#expose-incoming-ports) the port to be proxied, either by using the `EXPOSE` directive in their `Dockerfile` or by using the `--expose` flag to `docker run` or `docker create`. See [nginx-proxy](https://github.com/jwilder/nginx-proxy) for more informations. To generate automatically Let's Encrypt certificates see next section.

#### Separate Containers (recommended method)
nginx proxy can also be run as two separate containers using the [jwilder/docker-gen](https://github.com/jwilder/docker-gen)
image and the official [nginx](https://hub.docker.com/_/nginx/) image.

You may want to do this to prevent having the docker socket bound to a publicly exposed container service (avoid to mount the docker socket in the nginx exposed container). It's better in a security point of view.

To run nginx proxy as a separate container you'll need:

1) To mount the template file [nginx.tmpl](https://github.com/jwilder/nginx-proxy/blob/master/nginx.tmpl) into the docker-gen container. You can get the latest official [nginx.tmpl](https://github.com/jwilder/nginx-proxy/blob/master/nginx.tmpl) with a command like:
```bash
curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > /path/to/nginx.tmpl
```

2) Use the `com.github.jrcs.letsencrypt_nginx_proxy_companion.docker_gen` label on the docker-gen container, or explicitly set the `NGINX_DOCKER_GEN_CONTAINER` environment variable to the name or id of that container.

Examples:

* First start nginx (official image) with volumes:
```bash
$ docker run -d -p 80:80 -p 443:443 \
    --name nginx \
    -v /etc/nginx/conf.d  \
    -v /etc/nginx/vhost.d \
    -v /usr/share/nginx/html \
    -v /path/to/certs:/etc/nginx/certs:ro \
    --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
    nginx
```

* Second start the docker-gen container with the shared volumes and the template file:
```bash
$ docker run -d \
    --name nginx-gen \
    --volumes-from nginx \
    -v /path/to/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    --label com.github.jrcs.letsencrypt_nginx_proxy_companion.docker_gen \
    jwilder/docker-gen \
    -notify-sighup nginx -watch -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
```

* Then start this container:
```bash
$ docker run -d \
    --name nginx-letsencrypt \
    --volumes-from nginx \
    -v /path/to/certs:/etc/nginx/certs:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    jrcs/letsencrypt-nginx-proxy-companion
```

* Then start any containers to be proxied as described previously.

Note: If the docker-gen container name is static and you want to explicitly set it, use `-e NGINX_DOCKER_GEN_CONTAINER=nginx-gen`. The same thing is true with the nginx container (`-e NGINX_PROXY_CONTAINER=nginx`).


#### Let's Encrypt

To use the Let's Encrypt service to automatically create a valid certificate for virtual host(s).

Set the following environment variables to enable Let's Encrypt support for a container being proxied. This environment variables need to be declared in each to-be-proxied application containers.

- `LETSENCRYPT_HOST`
- `LETSENCRYPT_EMAIL`

The `LETSENCRYPT_HOST` variable most likely needs to be the same as the `VIRTUAL_HOST` variable and must be publicly reachable domains. Specify multiple hosts with a comma delimiter.

The following environment variables are optional and parameterize the way the Let's Encrypt client works.

- `LETSENCRYPT_KEYSIZE`

The `LETSENCRYPT_KEYSIZE` variable determines the size of the requested key (in bit, defaults to 4096).

##### multi-domain ([SAN](https://www.digicert.com/subject-alternative-name.htm)) certificates
If you want to create multi-domain ([SAN](https://www.digicert.com/subject-alternative-name.htm)) certificates add the base domain as the first domain of the `LETSENCRYPT_HOST` environment variable.

##### test certificates
If you want to create test certificates that don't have the 5 certs/week/domain limits define the `LETSENCRYPT_TEST` environment variable with a value of `true` (in the containers where you request certificates with LETSENCRYPT_HOST). If you want to do this globally for all containers, set ACME_CA_URI as described below.

##### Automatic certificate renewal
Every hour (3600 seconds) the certificates are checked and every certificate that will expire in the next [30 days](https://github.com/kuba/simp_le/blob/ecf4290c4f7863bb5427b50cdd78bc3a5df79176/simp_le.py#L72) (90 days / 3) are renewed.

##### Example:
```bash
$ docker run -d \
    --name example-app \
    -e "VIRTUAL_HOST=example.com,www.example.com,mail.example.com" \
    -e "LETSENCRYPT_HOST=example.com,www.example.com,mail.example.com" \
    -e "LETSENCRYPT_EMAIL=foo@bar.com" \
    tutum/apache-php
```

#### Force certificates renewal

If needed, you can force a running letsencrypt-nginx-proxy-companion container to renew all certificates that are currently in use. Replace `nginx-letsencrypt` with the name of your `letsencrypt-nginx-proxy-companion` container in the following command:

```bash
$ docker exec nginx-letsencrypt /app/force_renew
```

#### Optional container environment variables

Optional letsencrypt-nginx-proxy-companion container environment variables for custom configuration.

* `ACME_CA_URI` - Directory URI for the CA ACME API endpoint (default: ``https://acme-v01.api.letsencrypt.org/directory``). If you set it's value to `https://acme-staging.api.letsencrypt.org/directory` letsencrypt will use test servers that don't have the 5 certs/week/domain limits. You can also create test certificates per container (see [let's encrypt test certificates](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion/blob/doc/README.md#test-certificates))

For example

```bash
$ docker run -d \
    -e "ACME_CA_URI=https://acme-staging.api.letsencrypt.org/directory" \
    -v /path/to/certs:/etc/nginx/certs:rw \
    --volumes-from nginx-proxy \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    jrcs/letsencrypt-nginx-proxy-companion
```

* `DEBUG` - Set it to `true` to enable debugging of the entrypoint script and generation of LetsEncrypt certificates, which could help you pin point any configuration issues.

* `REUSE_KEY` - Set it to `true` to make simp_le reuse previously generated private key instead of creating a new one on certificate renewal. Recommended if you intend to use HPKP.

* The "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy" label - set this label on the nginx-proxy container to tell the docker-letsencrypt-nginx-proxy-companion container to use it as the proxy.

* The "com.github.jrcs.letsencrypt_nginx_proxy_companion.docker_gen" label - set this label on the docker-gen container to tell the docker-letsencrypt-nginx-proxy-companion container to use it as the docker-gen when it's split from nginx (separate containers).

* `ACME_TOS_HASH` - Let´s you pass an alternative TOS hash to simp_le, to support other CA´s ACME implentation.

#### Examples:

If you want other examples how to use this container, look at:

* [Evert Ramos's Examples](https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion) - using docker-compose version '3'
* [Karl Fathi's Examples](https://github.com/fatk/docker-letsencrypt-nginx-proxy-companion-examples)
* [More examples from Karl](https://github.com/pixelfordinner/pixelcloud-docker-apps/tree/master/nginx-proxy)
* [George Ilyes' Examples](https://github.com/gilyes/docker-nginx-letsencrypt-sample)
* [Dmitry's simple docker-compose example](https://github.com/dmitrym0/simple-lets-encrypt-docker-compose-sample)
* [Radek's docker-compose jenkins example](https://github.com/dataminelab/docker-jenkins-nginx-letsencrypt)
