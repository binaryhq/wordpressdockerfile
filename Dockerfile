FROM ubuntu:14.04
MAINTAINER ningappa <ningappa.kamate787@gmail.com>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Update
RUN apt-get update
RUN apt-get -y upgrade

#basic lamp requirments
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor pwgen mysql-server mysql-client apache2 libapache2-mod-php5 php5-mysql php-apc python-setuptools curl git unzip vim-tiny

# Wordpress Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl

RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
#RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# apache config
#ENV APACHE_RUN_USER www-data
#ENV APACHE_RUN_GROUP www-data
#ENV APACHE_LOG_DIR /var/log/apache2

ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh

ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

RUN rm -rf /var/lib/mysql/*

ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
RUN chmod 755 /*.sh

# php config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/short_open_tag\s*=\s*Off/short_open_tag = On/g" /etc/php5/apache2/php.ini

#wordpress installation
ADD https://wordpress.org/latest.tar.gz /var/www/latest.tar.gz
RUN cd /var/www/ && tar xvf latest.tar.gz && rm latest.tar.gz
RUN cp -rf  /var/www/wordpress/* /var/www/html/
RUN rm -rf /var/www/wordpress
RUN rm /var/www/html/index.html
RUN chown -R www-data:www-data /var/www/
# fix for php5-mcrypt
RUN /usr/sbin/php5enmod mcrypt
RUN a2enmod rewrite

ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

VOLUME  ["/etc/mysql", "/var/lib/mysql" ]

EXPOSE 80 3306
CMD ["/run.sh"]
