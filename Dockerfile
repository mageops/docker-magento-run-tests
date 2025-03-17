FROM rockylinux:9

# Install as much as we can of the base packages at first step to speed up the build
# Remove language override, may be required for some tests
# glibc-common is reinstalled to restore some missing locales
RUN sed -i 's/^\(override_install_langs.*\)$/#\1/' /etc/dnf/dnf.conf \
  && echo "fastestmirror=True" >> /etc/dnf/dnf.conf \
  && echo "max_parallel_downloads=20" >> /etc/dnf/dnf.conf \
  && ln -svf /usr/share/zoneinfo/UTC /etc/localtime \
  && dnf -y upgrade \
  && dnf -y install epel-release \
  && dnf -y reinstall glibc-common \
  && dnf -y install \
           dnf-utils \
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
           libzip \
           fribidi \
           graphviz \
           pngquant \
           libjpeg-turbo \
           optipng \
           gifsicle \
           jpegoptim \
  && dnf clean all

ARG ELASTICSEARCH_VERSION="7.17.3-x86_64"
ENV ELASTICSEARCH_VERSION="${ELASTICSEARCH_VERSION}" \
    ES_JAVA_OPTS="-Xms128m -Xmx128m"

RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch \
 && dnf -y install \
           "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.rpm" \
 && /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-phonetic \
 && /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu \
 && rm -rf /var/tmp/* /usr/share/elasticsearch/modules/x-pack-ml/platform/{darwin,windows}-* \
 # Remove auto hardcoded master hostname
 && sed '/cluster\.initial_master_nodes/d' -i /etc/elasticsearch/elasticsearch.yml \
 # Disable xpack security if enabled
 && sed -i 's/^xpack.security.enabled: true/xpack.security.enabled: false/' -i /etc/elasticsearch/elasticsearch.yml \
 && dnf clean all

ARG MYSQL_FLAVOR="mariadb"
ENV MYSQL_FLAVOR="${MYSQL_FLAVOR}"

ARG MARIADB_VERSION="11.4"
ENV MARIADB_VERSION="${MARIADB_VERSION}"

ARG MYSQL_VERSION=""
ENV MYSQL_VERSION="${MYSQL_VERSION}"

RUN set -exuo pipefail ; \
  if [ "$MYSQL_FLAVOR" = "mariadb" ];then \
    rpm --import https://dnf.mariadb.org/RPM-GPG-KEY-MariaDB \
    && echo -e "[mariadb]\nname = MariaDB\nbaseurl = http://dnf.mariadb.org/${MARIADB_VERSION}/rocky9-amd64\ngpgkey=https://dnf.mariadb.org/RPM-GPG-KEY-MariaDB\ngpgcheck=1\nenabled=1" > /etc/dnf.repos.d/MariaDB.repo \
    && dnf -y install MariaDB-server MariaDB-client \
    && rm -rf /var/lib/mysql; \
  elif [ "$MYSQL_FLAVOR" = "mysql" ];then \
    if [ "$MYSQL_VERSION" = "8.0" ];then \
      MYSQL_FILENAME=mysql80-community-release-el9-5.noarch.rpm; \
      MYSQL_MD5=4fa11545b76db63df0efe852e28c4d6b; \
    elif [ "$MYSQL_VERSION" = "8.4" ];then \  
      MYSQL_FILENAME=mysql84-community-release-el9-1.noarch.rpm; \
      MYSQL_MD5=15a20fea9018662224f354cb78b392e7; \
    else \
      echo "Uknown mysql version"; \
      exit 1; \
    fi; \
    curl -sLf "https://dev.mysql.com/get/$MYSQL_FILENAME" -o "$MYSQL_FILENAME" \
    && echo "$MYSQL_MD5  $MYSQL_FILENAME" md5sum -c \
    && dnf install -y "$MYSQL_FILENAME" \
    && rm "$MYSQL_FILENAME" \
    && dnf install -y mysql-community-server; \
  else \
    echo "Unknown MYSQL_FLAVOR=${MYSQL_FLAVOR}"; \
    exit 1; \
  fi; \
  dnf clean all

ARG PHP_VERSION="7.4"
ENV PHP_VERSION="${PHP_VERSION}"

RUN rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi \
 && dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm \
 && dnf -y module enable "php:remi-${PHP_VERSION}" \
 && dnf -y install \
            php php-gd php-pdo php-sodium php-json php-mysqlnd \
            php-soap php-xmlrpc php-xml php-intl php-mcrypt \
            php-mysql php-mbstring php-zip php-bcmath \
            php-opcache php-imagick php-curl php-gmp \
            php-pecl-redis php-pecl-zip \
  && if [ "$PHP_VERSION" = "7.4" ];then dnf -y install php74-php-pecl-apcu-bc; fi \
  && dnf clean all

ENV COMPOSER_HOME="/opt/composer"
ARG COMPOSER_VERSION="1"
ENV COMPOSER_VERSION="${COMPOSER_VERSION}"
ARG PHING_VERSION="2"
ENV PHING_VERSION="${PHING_VERSION}"

RUN mkdir /opt/composer \
  && curl getcomposer.org/installer -o /tmp/composer-setup \
  && COMPOSER_CHECKSUM="$(curl -fs https://composer.github.io/installer.sig)" \
  && php -r "if (hash_file('sha384', '/tmp/composer-setup') !== '${COMPOSER_CHECKSUM}') { exit(1); }" \
  && php /tmp/composer-setup "--${COMPOSER_VERSION}" --install-dir=/usr/bin --filename=composer \
  && rm /tmp/composer-setup \
  && composer global config bin-dir /usr/bin \
  && composer global require phing/phing "^${PHING_VERSION}" \
  && if [ "$COMPOSER_VERSION" = "1" ];then composer global require hirak/prestissimo; fi \
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
