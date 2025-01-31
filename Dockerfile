FROM nginx:alpine
MAINTAINER Adrien M amaurel90@gmail.com

ENV DEBUG=false RAP_DEBUG="info" 
ARG VERSION_RANCHER_GEN="artifacts/master"

WORKDIR /root/
RUN apk add --no-cache nano ca-certificates unzip wget bash openssl
RUN apk --update --no-cache add python3 augeas gcc python3-dev musl-dev libffi-dev openssl-dev py3-pip
RUN wget https://github.com/certbot/certbot/archive/v0.22.0.tar.gz && tar -xzf ./v0.22.0.tar.gz
WORKDIR /root/certbot-0.22.0
RUN pip install ./
# Install Forego & Rancher-Gen-RAP
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN wget "https://gitlab.com/nattaphat.la/rancher-gen-rap/builds/$VERSION_RANCHER_GEN/download?job=compile-go" -O /tmp/rancher-gen-rap.zip \
	&& unzip /tmp/rancher-gen-rap.zip -d /usr/local/bin \
	&& chmod +x /usr/local/bin/rancher-gen \
	&& chmod u+x /usr/local/bin/forego \
	&& rm -f /tmp/rancher-gen-rap.zip
	
#Copying all templates and script	
COPY /app/ /app/
WORKDIR /app/

# Seting up repertories & Configure Nginx and apply fix for very long server names
RUN chmod +x /app/letsencrypt.sh \
    && mkdir -p /etc/nginx/certs /etc/nginx/vhost.d /etc/nginx/conf.d /usr/share/nginx/html /etc/letsencrypt \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf \
    && chmod u+x /app/remove 

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh" ]
CMD ["forego", "start", "-r"]
