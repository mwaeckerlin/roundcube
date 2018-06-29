#!/bin/sh

# check database
if test -z "$DB_DSNW"; then
    if test -n "${MYSQL_ENV_MYSQL_PASSWORD:-${MYSQL_PASSWORD}}"; then
        export MYSQL_PASSWORD=${MYSQL_ENV_MYSQL_PASSWORD:-${MYSQL_PASSWORD}}
        export MYSQL_USER=${MYSQL_ENV_MYSQL_USER:-${MYSQL_USER:-roundcube}}
        export MYSQL_DATABASE=${MYSQL_ENV_MYSQL_DATABASE:-${MYSQL_DATABASE:-roundcube}}
        export DB_DSNW=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@mysql/${MYSQL_DATABASE}
    else
        export DB_DSNW="sqlite:///${SQLITE_PATH:-/var/tmp/sqlite.db}?mode=0646"
    fi
fi

# setup imap hosts
if test "${DEFAULT_HOST//, /}" != "${DEFAULT_HOST}"; then
    export DEFAULT_HOST="array('${DEFAULT_HOST//, /', '}')"
    export DEFAULT_HOST="${DEFAULT_HOST// => /' => '}"
else
    export DEFAULT_HOST="'${DEFAULT_HOST}'"
fi

# setup username domain mapping
if test "${USERNAME_DOMAIN//, /}" != "${USERNAME_DOMAIN}"; then
    export USERNAME_DOMAIN="array('${USERNAME_DOMAIN//, /', '}')"
    export USERNAME_DOMAIN="${USERNAME_DOMAIN// => /' => '}"
else
    export USERNAME_DOMAIN="'${USERNAME_DOMAIN}'"
fi

# setup configuration
cat > /etc/config.inc.php <<EOF
<?php

/* Local configuration for Roundcube Webmail */

// ----------------------------------
// SQL DATABASE
// ----------------------------------
// Database connection string (DSN) for read+write operations
// Format (compatible with PEAR MDB2): db_provider://user:password@host/database
// Currently supported db_providers: mysql, pgsql, sqlite, mssql, sqlsrv, oracle
// For examples see http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php
// NOTE: for SQLite use absolute path (Linux): 'sqlite:////full/path/to/sqlite.db?mode=0646'
//       or (Windows): 'sqlite:///C:/full/path/to/sqlite.db'
\$config['db_dsnw'] = '${DB_DSNW}';

// ----------------------------------
// IMAP
// ----------------------------------
// The IMAP host chosen to perform the log-in.
// Leave blank to show a textbox at login, give a list of hosts
// to display a pulldown menu or set one host as string.
// To use SSL/TLS connection, enter hostname with prefix ssl:// or tls://
// Supported replacement variables:
// %n - hostname (\$_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname \$_SERVER['HTTP_HOST'] without the first part)
// %s - domain name after the '@' from e-mail address provided at login screen
// For example %n = mail.domain.tld, %t = domain.tld
// WARNING: After hostname change update of mail_host column in users table is
//          required to match old user data records with the new host.
\$config['default_host'] = ${DEFAULT_HOST};

// ----------------------------------
// LOGGING/DEBUGGING
// ----------------------------------
// system error reporting, sum of: 1 = log; 4 = show
\$config['debug_level'] = 5;

// log driver:  'syslog', 'stdout' or 'file'.
\$config['log_driver'] = 'stdout';

// SMTP username (if required) if you use %u as the username Roundcube
// will use the current username for login
$config['smtp_user'] = '%u';

// SMTP password (if required) if you use %p as the password Roundcube
// will use the current user's password for login
$config['smtp_pass'] = '%p';

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
$config['support_url'] = 'http://mrw.world';

// replace Roundcube logo with this image
// specify an URL relative to the document root of this Roundcube installation
// an array can be used to specify different logos for specific template files, '*' for default logo
// for example array("*" => "/images/roundcube_logo.png", "messageprint" => "/images/roundcube_logo_print.png")
$config['skin_logo'] = 'https://logo.com/logo.png';

// use this folder to store log files
// must be writeable for the user who runs PHP process (Apache user if mod_php is being used)
// This is used by the 'file' log driver.
$config['log_dir'] = '';

// check client IP in session authorization
$config['ip_check'] = true;

// This key is used for encrypting purposes, like storing of imap password
// in the session. For historical reasons it's called DES_key, but it's used
// with any configured cipher_method (see below).
$config['des_key'] = 'R9usQvTmr4qXV5OaG1BmXwNP';

// Automatically add this domain to user names for login
// Only for IMAP servers that require full e-mail addresses for login
// Specify an array with 'host' => 'domain' values to support multiple hosts
// Supported replacement variables:
// %h - user's IMAP hostname
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
// %z - IMAP domain (IMAP hostname without the first part)
// For example %n = mail.domain.tld, %t = domain.tld
$config['username_domain'] = ${USERNAME_DOMAIN}

// ----------------------------------
// PLUGINS
// ----------------------------------
// List of active plugins (in plugins/ directory)
$config['plugins'] = array('acl', 'additional_message_headers', 'archive', 'attachment_reminder', 'autologon', 'database_attachments', 'debug_logger', 'emoticons', 'enigma', 'example_addressbook', 'filesystem_attachments', 'help', 'hide_blockquote', 'http_authentication', 'identicon', 'identity_select', 'jqueryui', 'krb_authentication', 'managesieve', 'markasjunk', 'new_user_dialog', 'new_user_identity', 'newmail_notifier', 'password', 'redundant_attachments', 'show_additional_headers', 'squirrelmail_usercopy', 'subscriptions_option', 'userinfo', 'vcard_attachments', 'virtuser_file', 'virtuser_query', 'zipdownload');

// the default locale setting (leave empty for auto-detection)
// RFC1766 formatted language name like en_US, de_DE, de_CH, fr_FR, pt_BR
$config['language'] = 'de_CH';

// Set the spell checking engine. Possible values:
// - 'googie'  - the default (also used for connecting to Nox Spell Server, see 'spellcheck_uri' setting)
// - 'pspell'  - requires the PHP Pspell module and aspell installed
// - 'enchant' - requires the PHP Enchant module
// - 'atd'     - install your own After the Deadline server or check with the people at http://www.afterthedeadline.com before using their API
// Since Google shut down their public spell checking service, the default settings
// connect to http://spell.roundcube.net which is a hosted service provided by Roundcube.
// You can connect to any other googie-compliant service by setting 'spellcheck_uri' accordingly.
$config['spellcheck_engine'] = 'pspell';

// show up to X items in messages list view
$config['mail_pagesize'] = 1000;

// show up to X items in contacts list view
$config['addressbook_pagesize'] = 1000;

// prefer displaying HTML messages
$config['prefer_html'] = false;

// save compose message every 300 seconds (5min)
$config['draft_autosave'] = 60;
EOF
