ARG BASE_IMAGE=alpine:3.18

FROM ${BASE_IMAGE}

LABEL maintainer="JH <jh@localhost>"

ARG BUILD_DATE
ARG NAME
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name=$NAME \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/johann8/" \
      org.label-schema.version=$VERSION

ENV OCS_VERSION 2.11.1

ENV MOD_PERL_VERSION 2.0.12

ARG APK_FLAGS="add --no-cache"

ENV APACHE_RUN_USER=apache \
    APACHE_RUN_GROUP=apache \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    OCS_DB_SERVER=dbsrv \
    OCS_DB_PORT=3306 \
    OCS_DB_USER=ocs \
    OCS_DB_PASS=ocs \
    OCS_DB_NAME=ocsweb \
    OCS_LOG_DIR=/var/log/ocsinventory-server \
    OCS_VARLIB_DIR=/var/lib/ocsinventory-reports/ \
    OCS_WEBCONSOLE_DIR=/usr/share/ocsinventory-reports \
    OCS_PERLEXT_DIR=/etc/ocsinventory-server/perl/ \
    OCS_PLUGINSEXT_DIR=/etc/ocsinventory-server/plugins/ \
    OCS_SSL_ENABLED=0 \
    OCS_SSL_WEB_MODE=DISABLED \
    OCS_SSL_COM_MODE=DISABLED \
    OCS_SSL_KEY=/path/to/key \
    OCS_SSL_CERT=/path/to/cert \
    OCS_SSL_CA=/path/to/ca

ENV TZ Europe/Berlin
ENV PHP_VERSION 81
ENV UPLOAD_MAX_FILESIZE 100M
ENV POST_MAX_SIZE 50M

RUN apk ${APK_FLAGS} \
    wget \
    curl \
    make \
    perl \
    bash \
    apache2 \
    tzdata \
    runit \
    fcgi \
    tar \
    php${PHP_VERSION} \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-zlib \
    php${PHP_VERSION}-apache2 \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-session \
    php${PHP_VERSION}-dom \
# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/

# compile apache2 mod_perl
RUN apk ${APK_FLAGS} \
    build-base \
    apache2-dev \
    perl-dev \
    apr-dev \
    apr-util-dev \
    && cd /tmp \
    && wget https://dlcdn.apache.org/perl/mod_perl-${MOD_PERL_VERSION}.tar.gz \
    && tar -zxvf mod_perl-${MOD_PERL_VERSION}.tar.gz \
    && cd mod_perl-${MOD_PERL_VERSION} \
    && perl Makefile.PL MP_APXS=/usr/bin/apxs \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/mod_perl-2.0.12.tar.gz \
    && rm -rf /tmp/mod_perl-2.0.12

# install ocsinventory dependencies
RUN apk ${APK_FLAGS} \
    perl-test-mockobject \
    perl-mime-tools \
    perl-fcgi \
    perl-xml-parser \
    perl-test-harness \
    perl-lwp-protocol-https \
    perl-net-ssleay \
    perl-net-ip \
    perl-xml-simple \
    perl-dbi \
    perl-dbd-mysql \
    perl-net-ip \
    perl-archive-zip \
    perl-switch \
    perl-mojolicious \
    perl-plack \
    perl-test-warn \
    perl-mojolicious \
    perl-digest-sha1 

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN wget https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${OCS_VERSION}/OCSNG_UNIX_SERVER-${OCS_VERSION}.tar.gz -P /tmp \
 && tar xzf /tmp/OCSNG_UNIX_SERVER-${OCS_VERSION}.tar.gz -C /tmp;

# install perl module
RUN echo "yes" | perl -MCPAN -e "install App::cpanminus" \
 && cpanm CPAN::DistnameInfo \
 && cpanm Apache::DBI \
 && cpanm XML::Entities \
 && cpanm XML::Parser::Lite --force \
 && cpanm SOAP::Lite --force \
 && rm -rf /root/.cpan

# install ocsinventory
RUN cd /tmp/OCSNG_UNIX_SERVER-${OCS_VERSION}/Apache/ \
 && perl Makefile.PL \
 && make \
 && make install

# clean
RUN apk del \
    build-base \
    apache2-dev \
    perl-dev \
    apr-dev \
    apr-util-dev \
    # Remove apk cache
    && rm -rf /var/cache/apk/*

#WORKDIR /etc/apache2/conf.d/

# Redirect Apache2 Logs to stdout e stderr
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/error.log

# Add configuration files
COPY rootfs/ /
COPY conf/ /tmp/conf

# make backup of apache conf dir
RUN tar czf /apache-conf-dir.tgz /etc/apache2/conf.d

VOLUME ["/var/lib/ocsinventory-reports", "/etc/ocsinventory-server", "/etc/apache2/conf.d", "/usr/share/ocsinventory-reports/ocsreports/extensions"]

EXPOSE 80

# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#entrypoint
#ENTRYPOINT [ "docker-entrypoint.sh" ]

# Let runit start apache2 & php-fpm
CMD [ "/bin/docker-entrypoint.sh" ]

# Configure a healthcheck to validate that everything is up&running
#HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping

ENV client_max_body_size=2M \
    clear_env=no \
    allow_url_fopen=On \
    allow_url_include=Off \
    display_errors=Off \
    file_uploads=On \
    max_execution_time=0 \
    max_input_time=-1 \
    max_input_vars=1000 \
    memory_limit=128M \
    #post_max_size=${POST_MAX_FILESIZE:-8M} \
    #upload_max_filesize=${UPLOAD_MAX_FILESIZE:-2M} \
    zlib.output_compression=On

