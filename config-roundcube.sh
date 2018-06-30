#!/bin/sh -e

# check database
if test -z "$DB_DSNW"; then
    if test -n "${MYSQL_ENV_MYSQL_PASSWORD:-${MYSQL_PASSWORD}}"; then
        export MYSQL_PASSWORD=${MYSQL_ENV_MYSQL_PASSWORD:-${MYSQL_PASSWORD}}
        export MYSQL_USER=${MYSQL_ENV_MYSQL_USER:-${MYSQL_USER:-roundcube}}
        export MYSQL_DATABASE=${MYSQL_ENV_MYSQL_DATABASE:-${MYSQL_DATABASE:-roundcube}}
        export DB_DSNW=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@mysql/${MYSQL_DATABASE}
    else
        export DB_DSNW="sqlite:///${SQLITE_PATH:-db/sqlite.db}?mode=0646"
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

# setup plugin list
if test -n "${PLUGINS}"; then
    export PLUGINS="array('${PLUGINS//, /', '}')"
fi

# setup configuration
test -e /etc/roundcube/config.inc.php || \
    cat > /etc/roundcube/config.inc.php <<EOF
<?php

/* Configuration for Roundcube Webmail */

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

// Automatically add this domain to user names for login
// Only for IMAP servers that require full e-mail addresses for login
// Specify an array with 'host' => 'domain' values to support multiple hosts
// Supported replacement variables:
// %h - user's IMAP hostname
// %n - hostname (\$_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname \$_SERVER['HTTP_HOST'] without the first part)
// %z - IMAP domain (IMAP hostname without the first part)
// For example %n = mail.domain.tld, %t = domain.tld
\$config['username_domain'] = ${USERNAME_DOMAIN};

// lowercase username? 0: no, 1: domain only, 2: yes
\$config['login_lc'] = ${LOGIN_LC:-2};

// Never use anything different than UTF-8!
\$config['password_charset'] = 'UTF-8';

// Automatically create a user entry in the roundcube database at
// first login in IMAP
\$config['auto_create_user'] = true;


// ----------------------------------
// SMTP
// ----------------------------------

// The SMTP server for outgoing messages. To use SSL/TLS connection,
// enter the hostname with prefix ssl:// or tls://.
//
// The host name can contain placeholders which will be replaced as
// follows:
//
// %h - user's IMAP hostname
// %n - hostname (\$_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname \$_SERVER['HTTP_HOST'] without the first part)
// %z - IMAP domain (IMAP hostname without the first part)
//
// For example %n = mail.domain.tld, %t = domain.tld

\$config['smtp_server'] = '${SMTP_SERVER:-%h}';

// SMTP username (if required) if you use %u as the username Roundcube
// will use the current username for login
\$config['smtp_user'] = '${SMTP_USER:-%u}';

// SMTP password (if required) if you use %p as the password Roundcube
// will use the current user's password for login
\$config['smtp_pass'] = '${SMTP_PASS:-%p}';


// ----------------------------------
// LOOK & FEEL
// ----------------------------------

// The name of your service (used to compose page titles)
\$config['product_name'] = '${PRODUCT_NAME}';

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
\$config['support_url'] = '${SUPPORT_URL}';

// replace Roundcube logo with this image
// specify an URL relative to the document root of this Roundcube installation
// an array can be used to specify different logos for specific template files, '*' for default logo
// for example array("*" => "/images/roundcube_logo.png", "messageprint" => "/images/roundcube_logo_print.png")
\$config['skin_logo'] = '${SKIN_LOGO}';


// ----------------------------------
// LOGGING/DEBUGGING
// ----------------------------------

// system error reporting, sum of: 1 = log; 4 = show
\$config['debug_level'] = 1;

// log driver:  'syslog', 'stdout' or 'file'.
\$config['log_driver'] = 'stdout';

// use this folder to store log files
// must be writeable for the user who runs PHP process (Apache user if mod_php is being used)
// This is used by the 'file' log driver.
\$config['log_dir'] = '';


// ----------------------------------
// SECURITY
// ----------------------------------

// check client IP in session authorization
\$config['ip_check'] = ${IP_CHECK:-false};

// This key is used for encrypting purposes, like storing of imap password
// in the session. For historical reasons it's called DES_key, but it's used
// with any configured cipher_method (see below).
\$config['des_key'] = '$(pwgen 24 1)';


// ----------------------------------
// Spell Check
// ----------------------------------

\$config['enable_spellcheck'] = $(test "${SPELLCHECK_ENGINE}" = "off" && echo "false" || echo "true");

// Set the spell checking engine. Possible values:
// - 'googie'  - the default (also used for connecting to Nox Spell Server, see 'spellcheck_uri' setting)
// - 'pspell'  - requires the PHP Pspell module and aspell installed
// - 'enchant' - requires the PHP Enchant module
// - 'atd'     - install your own After the Deadline server or check with the people at http://www.afterthedeadline.com before using their API
// Since Google shut down their public spell checking service, the default settings
// connect to http://spell.roundcube.net which is a hosted service provided by Roundcube.
// You can connect to any other googie-compliant service by setting 'spellcheck_uri' accordingly.
\$config['spellcheck_engine'] = '${SPELLCHECK_ENGINE:-pspell}';

\$config['spellcheck_uri'] = '${SPELLCHECK_URI:-http://spell.roundcube.net}';


// ----------------------------------
// General Configuration
// ----------------------------------

\$config['temp_dir'] = 'tmp';


// ----------------------------------
// USER DEFAULTS
// ----------------------------------

// the default locale setting (leave empty for auto-detection)
// RFC1766 formatted language name like en_US, de_DE, de_CH, fr_FR, pt_BR
\$config['language'] = '${LANGUAGE}';

\$config['skin'] = '${SKIN:-larry}';

// show up to X items in messages list view
\$config['mail_pagesize'] = ${MAIL_PAGESIZE:-1000};

// show up to X items in contacts list view
\$config['addressbook_pagesize'] = ${ADDRESSBOOK_PAGESIZE:-1000};

// prefer displaying HTML messages
\$config['prefer_html'] = ${PREFER_HTML:-false};

// save compose message every 300 seconds (5min)
\$config['draft_autosave'] = ${DRAFT_AUTOSAVE:-300};

// Behavior if a received message requests a message delivery notification (read receipt)
// 0 = ask the user
// 1 = send automatically
// 2 = ignore (never send or ask)
// 3 = send automatically if sender is in addressbook, otherwise ask the user
// 4 = send automatically if sender is in addressbook, otherwise ignore
\$config['mdn_requests'] = ${MDN_REQUESTS:-0};

// Set identities access level:
// 0 - many identities with possibility to edit all params
// 1 - many identities with possibility to edit all params but not email address
// 2 - one identity with possibility to edit all params
// 3 - one identity with possibility to edit all params but not email address
// 4 - one identity with possibility to edit only signature
\$config['identities_level'] = ${IDENTITIES_LEVEL:-0};


// ----------------------------------
// PLUGINS
// ----------------------------------
// List of active plugins (in plugins/ directory)
\$config['plugins'] = ${PLUGINS};

EOF
