FROM gliderlabs/alpine:3.9
LABEL maintainer "Jan Delgado <jdelgado@gmx.net>"


RUN  apk add --update asciidoc bash bc binutils bzip2 cdrkit coreutils diffutils findutils flex g++ gawk gcc gettext git grep intltool libxslt linux-headers make ncurses-dev patch perl python2-dev tar unzip  util-linux wget zlib-dev xz\
     && rm -rf /var/cache/apk/*

ADD https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64 /usr/local/bin/gosu
ADD etc/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/gosu

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

