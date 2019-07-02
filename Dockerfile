FROM centos:centos7

ARG PHP_VERSION="72"
ARG ELASTICSEARCH_VERSION="6.8.1"

ENV PHP_VERSION="${PHP_VERSION}" \
    ELASTICSEARCH_VERSION="${ELASTICSEARCH_VERSION}" \
    COMPOSER_HOME="/opt/composer"

RUN ln -svf /usr/share/zoneinfo/UTC /etc/localtime \
 && yum -y update \
 && yum -y reinstall glibc-common \
 && yum -y install \
           curl wget unzip git vim nano yum-utils sudo \
           epel-release \
           iproute python-setuptools hostname inotify-tools which \
           openssh-server openssh-clients \
           python-setuptools \
 && rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi \
 && yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
 && yum-config-manager --enable "remi-php${PHP_VERSION}" \
 && yum -y install \
           php php-devel php-gd php-pdo \
           php-soap php-xmlrpc php-xml php-intl php-mcrypt \
           php-mysql php-mbstring php-zip php-imagick php-bcmath \
           php-opcache php-imagick php-curl php-pecl-apcu pngquant \
 && rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch \
 && yum -y install \
           java-1.8.0-openjdk.x86_64 \
           "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.rpm" \
 && /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-phonetic \
 && /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu \
 && mkdir -p /var/log/elasticsearch \
 && chown elasticsearch:elasticsearch /var/log/elasticsearch \
 && mkdir /opt/composer \
 && curl getcomposer.org/installer -o /tmp/composer-setup \
 && php -r "if (hash_file('sha384', '/tmp/composer-setup') !== '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { exit(1); }" \
 && php /tmp/composer-setup --install-dir=/usr/bin --filename=composer \
 && rm /tmp/composer-setup \
 && composer global config bin-dir /usr/bin \
 && composer global require phing/phing \
 && yum clean all \
 && curl -L https://github.com/nicolas-van/multirun/releases/download/0.3.2/multirun-glibc-0.3.2.tar.gz | tar -xz -C /sbin \
 && chmod +x /sbin/multirun \
 && mkdir -p /var/www/html \
 && echo -e "#!/bin/bash \n set -e -x \n /usr/bin/mgs-fix-perms \n chown elasticsearch:elasticsearch /var/lib/elasticsearch \n sudo -E -u elasticsearch -g elasticsearch /usr/share/elasticsearch/bin/elasticsearch" > /usr/bin/elasticsearch-server \
 && echo -e "#!/bin/bash \n set -e -x \n curl -sf localhost:9200 2>&1 > /dev/null && mysqladmin ping 2>&1 > /dev/null" > /usr/bin/healthcheck \
 && chmod +x /usr/bin/{elasticsearch-server,healthcheck}

ARG MARIADB_VERSION="10.2"
ENV MARIADB_VERSION="${MARIADB_VERSION}"

RUN rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB \
     && echo -e "[mariadb]\nname = MariaDB\nbaseurl = http://yum.mariadb.org/${MARIADB_VERSION}/centos7-amd64\ngpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB\ngpgcheck=1\nenabled=1" > /etc/yum.repos.d/MariaDB.repo \
     && yum -y install MariaDB-server MariaDB-client \
     && echo -e "#!/bin/bash \n set -e -x \n /usr/bin/mgs-fix-perms \n chown mysql:mysql /var/lib/mysql \n mysql_install_db --basedir=/usr --datadir=/var/lib/mysql --user=mysql \n sudo -E -u mysql -g mysql /usr/sbin/mysqld" > /usr/bin/mysql-server \
     && chmod +x /usr/bin/mysql-server \
     && yum clean all

COPY /rootfs /

RUN chmod 440 /etc/sudoers \
    && mkdir -p /var/www/html/{generated,var,dev/tests/integration/tmp} \
    && chmod 777 /var/www/html/{generated,var,dev/tests/integration/tmp} /tmp

ENV ES_JAVA_OPTS="-Xms128m -Xmx128m" \
    DB_USER="magento2" \
    DB_PASS="magento2" \
    DB_NAME="magento2_integration_tests"

VOLUME /var/lib/mysql/ \
       /var/lib/elasticsearch/ \
       /var/www/html/generated/ \
       /var/www/html/var/ \
       /var/www/html/dev/tests/integration/tmp/

WORKDIR /var/www/html

EXPOSE 22 80 3306 9200

ENTRYPOINT ["/sbin/multirun"]

CMD ["/usr/bin/elasticsearch-server", "/usr/bin/mysql-server"]

HEALTHCHECK --timeout=10s --interval=10s --start-period=10s CMD /usr/bin/healthcheck
