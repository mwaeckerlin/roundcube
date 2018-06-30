FROM mwaeckerlin/php-fpm
MAINTAINER mwaeckerlin

ENV PLUGINS       "acl, additional_message_headers, archive, attachment_reminder, emoticons, filesystem_attachments, help, hide_blockquote, jqueryui, managesieve, markasjunk, new_user_dialog, newmail_notifier, subscriptions_option, vcard_attachments, zipdownload"

ENV WEB_ROOT_PATH /usr/share/webapps/roundcube
ENV CONTAINERNAME "roundcube"
USER root
ADD config-roundcube.sh /config-roundcube.sh
RUN apk update && \
    apk add roundcubemail pwgen && \
    mkdir /usr/share/webapps/roundcube/tmp && \
    mkdir /usr/share/webapps/roundcube/db && \
    chown -R $WWWUSER /etc/roundcube /usr/share/webapps/roundcube/tmp /usr/share/webapps/roundcube/db
USER $WWWUSER

VOLUME /etc/roundcube
VOLUME /usr/share/webapps/roundcube/db
