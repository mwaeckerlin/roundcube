FROM mwaeckerlin/base
MAINTAINER mwaeckerlin

RUN apk update && apk add roundcubemail-installer roundcubemail

VOLUME /usr/share/webapps/roundcube
VOLUME /etc/roundcube
