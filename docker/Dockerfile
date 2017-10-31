FROM debian:8 
LABEL maintainer "Jan Delgado <jdelgado@gmx.net>"


RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get -t jessie-backports install "gosu" \
    && apt-get install -y --no-install-recommends ca-certificates wget  \
                  subversion build-essential libncurses5-dev zlib1g-dev \
                  gawk git ccache gettext libssl-dev xsltproc file unzip \
                  python \
    && apt-get autoclean \
    && apt-get clean \
    && apt-get autoremove\
    && rm -rf /var/lib/apt/lists/*

ADD etc/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh 

# install the image builder. use tmpfile so that tar's compression
# autodetection works.
ARG BUILDER_URL
RUN mkdir -p /lede/imagebuilder && \
    wget  --progress=bar:force:noscroll $BUILDER_URL -O /tmp/imagebuilder && \
      tar xf /tmp/imagebuilder --strip-components=1 -C /lede/imagebuilder &&\
      rm -f /tmp/imagebuilder


WORKDIR "/lede/imagebuilder"
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

