FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root

RUN apt-get update && apt-get -y install apt-utils
RUN apt-get update && apt-get -y install \
    sudo \
    curl \
    perl \
    wget
ADD install_texlive.sh /root/
RUN chmod +x /root/install_texlive.sh
RUN /root/install_texlive.sh
RUN rm /usr/local/texlive/current/texmf-dist/doc

ENV PATH "$PATH:/usr/local/texlive/current/bin/x86_64-linux"