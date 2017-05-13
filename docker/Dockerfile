FROM debian:8 
LABEL maintainer "Jan Delgado <delgadoprojects@gmail.com>"

ARG BUILDER_URL

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
RUN apt-get update \
    && apt-get -t jessie-backports install "gosu" \
    && apt-get install -y --no-install-recommends ca-certificates wget  \
                       subversion build-essential libncurses5-dev zlib1g-dev \
                       gawk git ccache gettext libssl-dev xsltproc file unzip \
                       python 

RUN mkdir -p /lede/imagebuilder

# install the image builder. use tmpfile so that tar's compression
# autodetection works.
RUN wget $BUILDER_URL -O /tmp/imagebuilder && \
      tar xf /tmp/imagebuilder --strip-components=1 -C /lede/imagebuilder &&\
      rm -f /tmp/imagebuilder

WORKDIR "/lede/imagebuilder"

ADD etc/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh 

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

