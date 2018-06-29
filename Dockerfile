FROM mwaeckerlin/php-fpm
MAINTAINER mwaeckerlin

ENV WEB_ROOT_PATH /usr/share/webapps/roundcube
ENV CONTAINERNAME "roundcube"
USER root
ADD start.sh /start.sh
RUN apk update && \
    apk add roundcubemail && \
    mkdir /usr/share/webapps/roundcube/tmp && \
    chown -R $WWWUSER /etc/roundcube /usr/share/webapps/roundcube/tmp
USER $WWWUSER
