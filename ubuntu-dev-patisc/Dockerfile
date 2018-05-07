FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
ENV TERM xterm-256color

RUN apt-get update && apt-get -y install apt-utils
RUN apt-get update && apt-get -y install \
    git \
    scons \
    g++ \
    doxygen \
    graphviz