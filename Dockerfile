FROM alpine:3.3

MAINTAINER Yves Blusseau <90z7oey02@sneakemail.com> (@blusseau)

ENV DEBUG=false              \
	DOCKER_GEN_VERSION=0.7.3 \
	DOCKER_HOST=unix:///var/run/docker.sock

RUN apk --update add bash curl ca-certificates procps jq tar libffi-dev py-pip openssl-dev git gcc python-dev musl-dev && \
	curl -L -O https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
	tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
	rm -f docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

WORKDIR /app

# Install simp_le program
COPY /install_simp_le.sh /app/install_simp_le.sh
RUN chmod +rx /app/install_simp_le.sh && sync && /app/install_simp_le.sh && rm -f /app/install_simp_le.sh

# Install Dehydrated with Cloudflare hook
COPY /install_dehydrated_cloudflare.sh /app/install_dehydrated_cloudflare.sh
RUN chmod +rx /app/install_dehydrated_cloudflare.sh && sync && /app/install_dehydrated_cloudflare.sh && rm -f /app/install_dehydrated_cloudflare.sh

# Clean up
COPY /clean.sh /app/clean.sh
RUN chmod +rx /app/clean.sh && sync && /app/clean.sh && rm -f /app/clean.sh

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh" ]
CMD ["/bin/bash", "/app/start.sh" ]

COPY /app/ /app/
