FROM ubuntu:22.04 as base
LABEL maintainer "Jan Delgado <jdelgado@gmx.net>"

RUN    apt-get update\
    && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential\
         libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev\
         xsltproc rsync wget unzip python3 python3-distutils file\
    && rm -rf /var/lib/apt/lists/*

ADD etc/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh 

FROM base

# install the image builder. use tmpfile so that tar's compression
# autodetection works.
ARG BUILDER_URL
ADD $BUILDER_URL /tmp/imagebuilder

RUN    mkdir -p /lede/imagebuilder\
    && tar xf /tmp/imagebuilder --strip-components=1 -C /lede/imagebuilder\
    && rm -f /tmp/imagebuilder 

WORKDIR "/lede/imagebuilder"
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

