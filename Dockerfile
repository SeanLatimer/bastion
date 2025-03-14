FROM alpine:3.21
WORKDIR /root

# Update core packages
RUN apk update && apk upgrade

RUN apk add openssh curl \
  && rm -rf /var/cache/apk/*

#RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
RUN echo "root:$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 36 ; echo '')" | chpasswd

COPY entrypoint.sh .
COPY sshd_config /etc/ssh/sshd_config

RUN mkdir ~/.ssh \
  && chmod 0700 ~/.ssh \
  && touch ~/.ssh/authorized_keys \
  && chmod 0600 ~/.ssh/authorized_keys

EXPOSE 22

ENTRYPOINT [ "/root/entrypoint.sh" ]
CMD ["/usr/sbin/sshd", "-D"]
