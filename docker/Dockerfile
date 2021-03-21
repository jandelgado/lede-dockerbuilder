FROM alpine:3.13.1
LABEL maintainer "Jan Delgado <jdelgado@gmx.net>"

RUN  apk add --update asciidoc bash bc binutils bzip2 cdrkit coreutils\
                      diffutils findutils flex g++ gawk gcc gettext git grep\
                      intltool libxslt linux-headers make ncurses-dev patch\
                      perl python2-dev tar unzip  util-linux wget zlib-dev xz\
                      python3 rsync\
                      su-exec\
     && rm -rf /var/cache/apk/*

ADD etc/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh 

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

