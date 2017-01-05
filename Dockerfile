FROM ubuntu:14.04

# that's me!
MAINTAINER Alex K, allixender@googlemail.com

ENV CGI_DIR /usr/lib/cgi-bin
ENV CGI_DATA_DIR /usr/lib/cgi-bin/data
ENV WWW_DIR /var/www/html


ADD build-script.sh /opt
RUN chmod +x /opt/build-script.sh \
  && /opt/build-script.sh

# RUN rm -rf $WWW_DIR/*
ADD cgi-bin $CGI_DIR/
ADD data $CGI_DATA_DIR/

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod cgid

RUN mkdir -p $CGI_DATA_DIR/cache
RUN chown -R www-data:www-data $CGI_DATA_DIR
RUN ln -s $CGI_DIR/zoo_loader.cgi $CGI_DIR/wps

# COPY index.html $CGI_DIR/
COPY index.html $WWW_DIR/

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

# the Apache HTTPD server binds to 80 - expose that port
EXPOSE 80
# EXPOSE 443

# maybe separate the built image from a subsequent image that only inherits from this here and runs Apache2?
CMD ["/usr/sbin/apache2ctl","-k", "start", "-D",  "FOREGROUND"]