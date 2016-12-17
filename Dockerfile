FROM repmovsd/kbuilder:latest
MAINTAINER rep.movsd@gmail.com

USER root
ADD ./scripts/ /usr/local/scripts/kbuilder

USER nimbix
ADD ./NAE/ /etc/NAE/
