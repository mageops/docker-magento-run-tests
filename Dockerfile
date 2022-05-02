FROM centos:centos7

# Install as much as we can of the base packages at first step to speed up the build
# Remove language override, may be required for some tests
# glibc-common is reinstalled to restore some missing locales
RUN sed -i 's/^\(override_install_langs.*\)$/#\1/' /etc/yum.conf \
  && ln -svf /usr/share/zoneinfo/UTC /etc/localtime \
  && yum -y install epel-release \
  && yum -y reinstall glibc-common \
  && yum -y install \
           yum-utils \
           curl \
           wget \
           unzip \
           git \
           vim \
           nano \
           sudo \
           iproute \
           python-setuptools \
           hostname \
           inotify-tools \
           which \
           openssl \
           openssh \
           python-setuptools \
           pngquant \
           java-1.8.0-openjdk-headless \
           boost-program-options \
           libaio \
           lsof \
           make \
           autoconf \
           automake \
           cairo \
           apr \
           gcc \
           gcc-c++ \
           fontconfig \
           libmcrypt \
           libzip5 \
           fribidi \
           graphviz \
           pngquant \
           libjpeg-turbo \
           optipng \
           gifsicle \
           jpegoptim \
  && yum clean all

ARG ELASTICSEARCH_VERSION="7.17.3-x86_64"
ENV ELASTICSEARCH_VERSION="${ELASTICSEARCH_VERSION}" \
    ES_JAVA_OPTS="-Xms128m -Xmx128m"

RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch \
 && yum -y install \
           "https://artifacts.elastic.co/downloads/elasticsearch/ ${ELASTICSEARCH_VERSION}.rpm" \
 && /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-phonetic \
 && /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu \
 && rm -rf /var/tmp/* /usr/share/elasticsearch/modules/x-pack-ml/platform/{darwin,windows}-* \
 && yum clean all

ARG MARIADB_VERSION="10.8"
ENV MARIADB_VERSION="${MARIADB_VERSION}"

RUN rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB \
 && echo -e "[mariadb]\nname = MariaDB\nbaseurl = http://yum.mariadb.org/${MARIADB_VERSION}/centos7-amd64\ngpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB\ngpgcheck=1\nenabled=1" > /etc/yum.repos.d/MariaDB.repo \
 && yum -y install MariaDB-server MariaDB-client \
 && rm -rf /var/lib/mysql/ib_logfile* \
 && yum clean all

ARG PHP_VERSION="74"
ENV PHP_VERSION="${PHP_VERSION}"

RUN rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi \
 && yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
 && yum-config-manager --enable "remi-php${PHP_VERSION}" \
 && yum -y install \
            php php-gd php-pdo php-sodium php-json php-mysqlnd \
            php-soap php-xmlrpc php-xml php-intl php-mcrypt \
            php-mysql php-mbstring php-zip php-bcmath \
            php-opcache php-imagick php-curl php-gmp \
            php-pecl-apcu-bc php-pecl-redis php-pecl-zip \
  && yum clean all

ENV COMPOSER_HOME="/opt/composer"
ARG COMPOSER_VERSION="1"
ENV COMPOSER_VERSION="${COMPOSER_VERSION}"

RUN mkdir /opt/composer \
  && curl getcomposer.org/installer -o /tmp/composer-setup \
  && COMPOSER_CHECKSUM="$(curl -fs https://composer.github.io/installer.sig)" \
  && php -r "if (hash_file('sha384', '/tmp/composer-setup') !== '${COMPOSER_CHECKSUM}') { exit(1); }" \
  && php /tmp/composer-setup "--${COMPOSER_VERSION}" --install-dir=/usr/bin --filename=composer \
  && rm /tmp/composer-setup \
  && composer global config bin-dir /usr/bin \
  && composer global require phing/phing hirak/prestissimo \
  && curl -L https://github.com/nicolas-van/multirun/releases/download/0.3.2/multirun-glibc-0.3.2.tar.gz | tar -xz -C /sbin \
  && chmod +x /sbin/multirun \
  && mkdir -p /var/www/html \
  && echo -e "#!/bin/bash \n set -e -x \n curl -sf localhost:9200 2>&1 > /dev/null && mysqladmin ping 2>&1 > /dev/null" > /usr/bin/healthcheck \
  && chmod +x /usr/bin/healthcheck

COPY /rootfs /

RUN chmod 440 /etc/sudoers \
 && mkdir -p /var/www/html/{generated,var,dev/tests/integration/tmp} \
 && chmod 777 /var/www/html/{generated,var,dev/tests/integration/tmp} /tmp

ENV DB_USER="magento2" \
    DB_PASS="magento2" \
    DB_NAME="magento2_integration_tests"

VOLUME /var/lib/mysql/ \
       /var/lib/elasticsearch/ \
       /var/www/html/generated/ \
       /var/www/html/var/ \
       /var/www/html/dev/tests/integration/tmp/

WORKDIR /var/www/html

EXPOSE 22 80 3306 9200

ENV CONTAINER_TIMEOUT=1h

ENTRYPOINT ["/sbin/multirun"]

CMD ["/usr/sbin/start-elasticsearch", "/usr/sbin/start-mysql", "/usr/bin/container-timeout"]

HEALTHCHECK --timeout=10s --interval=10s --start-period=10s CMD /usr/bin/healthcheck
