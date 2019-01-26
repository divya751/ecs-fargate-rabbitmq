#
# RabbitMQ Dockerfile
#
# https://github.com/dockerfile/rabbitmq
#

# Pull base image.
#FROM dockerfile/ubuntu
FROM ubuntu:latest

# Add files.
ADD bin/rabbitmq-start /usr/local/bin/
RUN  apt-get update \
  && apt-get install -y wget \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y gnupg
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

# Install RabbitMQ.
RUN \
  #wget -qO - https://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add - && \
  wget -qO - https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | apt-key add - && \
  echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y rabbitmq-server && \
  rm -rf /var/lib/apt/lists/* && \
  rabbitmq-plugins enable rabbitmq_management && 
  ENV HOME /var/lib/rabbitmq
  ENV PATH /usr/lib/rabbitmq/bin:$PATH
  
  RUN mkdir -p /var/lib/rabbitmq /etc/rabbitmq \
  && echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config \
  && chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /etc/rabbitmq \
  && chmod -R 777 /var/lib/rabbitmq /etc/rabbitmq \
  && chmod +x /usr/local/bin/rabbitmq-start

# Define environment variables.

ENV RABBITMQ_LOG_BASE /data/log
ENV RABBITMQ_MNESIA_BASE /data/mnesia

# Define mount points.
VOLUME ["/data/log", "/data/mnesia", "/var/lib/rabbitmq"]

# add a symlink to the .erlang.cookie in /root so we can "docker exec rabbitmqctl ..." without gosu
RUN ln -sf /var/lib/rabbitmq/.erlang.cookie /root/

RUN ln -sf /usr/lib/rabbitmq/lib/rabbitmq_server-$RABBITMQ_VERSION/plugins /plugins

RUN apt-get update && apt-get install -y python python-pip python-dev build-essential vim \
	&& pip install pika

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
RUN rabbitmq-plugins enable --offline rabbitmq_management
ENTRYPOINT ["docker-entrypoint.sh"]

# Define working directory.
WORKDIR /data

# Define default command.
CMD ["rabbitmq-start"]

# Expose ports.
EXPOSE 5672
EXPOSE 15672
