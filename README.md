Docker Image for Roundcube Webmailer
====================================

[Roundcube] webmail is a browser-based multilingual IMAP client with an application-like user interface. It provides full functionality you expect from an email client, including MIME support, address book, folder manipulation, message searching and spell checking.

This image inherits [mwaeckerlin/nginx] and [mwaeckerlin/php-fpm] to handle the network traffix and execute PHP. So all features of those images are also available here in [mwaeckerlin/roundcube].


Volumes
-------

Configuration is stored in `/etc/roundcube`. Make sure to store this in a persistent volume, otherwise you will lose your DES-key which is used to store encrypted passwords and your database will become unavailable.

Also permanently store the database volume, whether it is external (e.g. [mysql]) or internal in SQLite (defaults to `/usr/share/webapps/roundcube/db/sqlite.db`).


Configuration
-------------

Mainly you need to specify: A database for user settings, the IMAP and SMTP servers. All configuration is optional and has useful defaults.

Configuration is done using environment variables. MySQL database can be configured from docker `--link`, then the environment variables are passed implicitly.


### Database

A database is required to store user configurations. By default, SQLite is used in `/usr/share/webapps/roundcube/db/sqlite.db`. Make sure, you store the database on a persistent volume.

You have different options to connect to a database. I recommend using [mysql] must have been initialized with the environment variables `MYSQL_PASSWORD`, `MYSQL_USER` and `MYSQL_DATABASE`, which are then inherited and used by [mwaeckerlin/roundcube]


#### MySQL

You can link to a mysql database using `--link your-db-container:mysql`. Here it is important to name the database `mysql` (the text after the colon `:`). Your [mysql] must be initialized with the environment variables below.

Or you can connect to a local MySQL server (e.g. in docker swarm) using the following environment variables:

 - `MYSQL_PASSWORD`: Database password, must be given.
 - `MYSQL_USER`: Database user, defaults to `roundcube`.
 - `MYSQL_DATABASE`: Database name, defaults to `roundcube`.
 
 Database and user must already exist.


#### SQLite

If no database is configured, [mwaeckerlin/roundcube] defaults to SQLite. Do not forget to store the database in a volume and do backups. You can specify the path to the database in variable:

  - `SQLITE_PATH`: Path to the SQLite database file, defaults to `/usr/share/webapps/roundcube/db/sqlite.db`.


#### Other Databases

You can specify any database by configuring the following environment variable:

 - `DB_DSNW`: Database connection in [PEAR DSN] format


### IMAP Server

An IMAP server is the server where your mails are stored. SMTP ist the protocol to read and andministrate your mails. By default, a user can specify any IMAP server at login.

Define which IMAP servers can be accessed by defingen the environment variable:

 - `DEFAULT_HOST`: Defines zero, one or list of IMAP servers, it can be:
 
     - **Empty**: (default) The login screen provides a text box where you need to enter the IMAP host which you want to connect to.
     
     - One hostname: Exactly this host is connected, you can't choose.
     
     - A comma plus space (`, `) separated list of hosts, presented as combobox (don't use quotes). The number of spaces (one after comma) is relevant.
    
       Examples:

       `-e 'DEFAULT_HOST=mail.example.com => Default Server, ssl://webmail.example.com => Webmail Server, ssl://mail.example.com:993 => Secure Webmail Server'` 

       `-e 'DEFAULT_HOST='` 

       `-e 'DEFAULT_HOST=ssl://mail.example.com'`

    Use host prefix `ssl://` or `tls://` to use SSL or TLS connections (strongly recommended).
    
    You can add a name to a hostname by using a space enclodes equal+geater dash (` => `), the name cannot contain a comma. The number of spaces (one before and after dash) is relevant.
    
 - `USERNAME_DOMAIN`: Automatically add this domain to user names for login. Only needed for IMAP servers that require full email addresses for login. Specify an array with `host => domain` values to support multiple hosts. Syntax is the the same, as for `DEFAULT_HOST`.
 
 - `LOGIN_LC`: Should the username be converted to lower case?
     - `0`: disabled, don't convert the user name
     - `1`: domain part only
     - **`2`**: lower-case the entire user name (default)


### SMTP

SMTP is the protocol to send mails. By default, the SMTP server is identical to the IMAP server with the same username and password for login.

 - `SMTP_SERVER`: The SMTP server for outgoing messages. To use SSL/TLS connection, enter the hostname with prefix `ssl://` or `tls://`. Defaults to `%h`.

   The host name can contain placeholders which will be replaced as follows:

    - `%h` - user's IMAP hostname
    - `%n` - hostname (`$_SERVER['SERVER_NAME']`)
    - `%t` - hostname without the first part
    - `%d` - domain (http hostname `$_SERVER['HTTP_HOST']` without the first part)
    - `%z` - IMAP domain (IMAP hostname without the first part)

   For example `%n` = `mail.domain.tld`, `%t` = `domain.tld`

 - `SMTP_USER`: SMTP username (if required). If you use `%u` as the username it is the same username as for IMAP login. Default is `%u`.
 
 - `SMTP_PASS`: SMTP password (if required) if you use `%p` as the password it is the same username as for IMAP login. Default is `%p`.


### Look & Feel

 - `PRODUCT_NAME`: The name of your service (used to compose page titles). Empty by default.

 - `SKIN_LOGO`: URL to a logo that replaces the Rouncube logo. Empty by default.
 
 - `SUPPORT_URL`: URL where a user can get support for this Roundcube installation. Empty by default.
 
 
### Security

 - `IP_CHECK`: Check client IP in session authorization. This increases security but can cause sudden logouts when someone uses a proxy with changing IPs. Defaults to `false`.
 
 
### Spellcheck

  - `SPELLCHECK_ENGINE`: Set the spell checking engine. Possible values:
  
     - `off`: Disable spell checking.
     
     - **`pspell`**: Uses the PHP Pspell module and aspell installed. This is default.
     
     - `enchant`: Uses the PHP Enchant module
     
     - `googie`: Implies that the message content will be sent to external server to check the spelling. Since Google shut down their public spell checking service, the default settings connect to http://spell.roundcube.net which is a hosted service provided by Roundcube. You can connect to any other googie-compliant service by setting `SPELLCHECK_URI` accordingly.
     
     - ~~`atd`~~: unsupported (After the Deadline server)
     
### User Defaults

These variables set the user's defaults. The user can change the values in their settings.

 - `LANGUAGE`: The default locale setting (leave empty for auto-detection). RFC1766 formatted language name like `en_US`, `de_DE`, `de_CH`, `fr_FR`, `pt_BR`, …. Empty (auto-detect) by default.
 
 - `SKIN`: Look and feel. `classic` or `larry`, defaults to `larry`.
 
 - `PREFER_HTML`: Whether mails should be shown as text or html. Defaults to `false` (text), due to security reasons.
 
 - `DRAFT_AUTOSAVE`: Save compose message every defined number of seconds. Defaults to `300` (5min).

 - `MDN_REQUESTS`: Behavior if a received message requests a message delivery notification (read receipt). Defaults to 0

    - **`0`**: Ask the user. This is the default.
    
    - `1`: Send automatically.
    
    - `2`: Ignore (never send or ask).
    
    - `3`: Send automatically if sender is in addressbook, otherwise ask the user.
    
    - `4`: Send automatically if sender is in addressbook, otherwise ignore.

 - `IDENTITIES_LEVEL`: Set identities access level.
 
     - **`0`**: Many identities with possibility to edit all params. This is default.
     
     - `1`: Many identities with possibility to edit all params but not email address.
     
     - `2`: One identity with possibility to edit all params.
     
     - `3`: One identity with possibility to edit all params but not email address.
     
     - `4`: One identity with possibility to edit only signature.
     

#### Plugins

 - `PLUGINS`: A comma plus space (`, `) separated list of plugins (don't use quotes). The number of spaces (one after comma) is relevant. Please consider checking dependencies of enabled plugins. Defaults to `acl, additional_message_headers, archive, attachment_reminder, emoticons, filesystem_attachments, help, hide_blockquote, jqueryui, managesieve, markasjunk, new_user_dialog, newmail_notifier, subscriptions_option, vcard_attachments, zipdownload`.

   Available plugins at the time of writing (for the current list, see `ls -1 /usr/share/webapps/roundcube/plugins` inside the [mwaeckerlin/roundcube] docker image):

    - **`acl`**: IMAP Folders Access Control Lists Management (RFC4314, RFC2086).
    
    - **`additional_message_headers`**: Very simple plugin which will add additional headers to or remove them from outgoing messages.
    
    - **`archive`**: This adds a button to move the selected messages to an archive folder. The folder (and the optional structure of subfolders) can be selected in the settings panel.
    
    - **`attachment_reminder`**:  Roundcube plugin reminds the user to attach a file if the composed message text indicates that there should be any.
    
    - `autologon`: Sample plugin to try out some hooks.
    
    - `database_attachments`: This plugin which provides database backed storage for temporary attachment file handling. The primary advantage of this plugin is its compatibility with round-robin dns multi-server Roundcube installations.
    
    - `debug_logger`: Enhanced logging for debugging purposes. It is not recommened to be enabled on production systems without testing because of the somewhat increased memory, cpu and disk i/o overhead.
    
    - **`emoticons`**: Plugin that adds emoticons support.
    
    - `enigma`: Server-side PGP Encryption for Roundcube.
    
    - `example_addressbook`: Sample plugin to add a new address book with just a static list of contacts.
    
    - **`filesystem_attachments`**: This is a core plugin which provides basic, filesystem based attachment temporary file handling. This includes storing attachments of messages currently being composed, writing attachments to disk when drafts with attachments are re-opened and writing attachments to disk for inline display in current html compositions.
    
    - **`help`**: Plugin adds a new item (Help) in taskbar.
    
    - **`hide_blockquote`**: This allows to hide long blocks of cited text in messages.
    
    - `http_authentication`: HTTP Basic Authentication.
    
    - `identicon`: Displays Github-like identicons for contacts/addresses without photo specified.
    
    - `identity_select`: On reply to a message user identity selection is based on content of standard headers like From, To, Cc and Return-Path. Here you can add header(s) set by your SMTP server (e.g. Delivered-To, Envelope-To, X-Envelope-To, X-RCPT-TO) to make identity selection more accurate.
    
    - **`jqueryui`**: Plugin adds the complete jQuery-UI library including the smoothness theme to Roundcube. This allows other plugins to use jQuery-UI without having to load their own version. The benefit of using one central jQuery-UI is that we wont run into problems of conflicting jQuery libraries being loaded. All plugins that want to use jQuery-UI should use this plugin as a requirement.
    
    - `krb_authentication`: N/A
    
    - **`managesieve`**: Adds a possibility to manage Sieve scripts (incoming mail filters). It's clickable interface which operates on text scripts and communicates with server using managesieve protocol. Adds Filters tab in Settings.
    
    - **`markasjunk`**: Adds a new button to the mailbox toolbar to mark the selected messages as Junk and move them to the configured Junk folder.
    
    - **`new_user_dialog`**: When a new user is created, this plugin checks the default identity and sets a session flag in case it is incomplete. An overlay box will appear on the screen until the user has reviewed/completed his identity.
    
    - `new_user_identity`: Populates a new user's default identity from LDAP on their first visit.
    
    - **`newmail_notifier`**: Supports three methods of notification: 1. Basic - focus browser window and change favicon 2. Sound - play wav file 3. Desktop - display desktop notification (using HTML5 Notification API feature).
    
    - `password`: Password Change for Roundcube. Plugin adds a possibility to change user password using many methods (drivers) via Settings/Password tab.
    
    - `redundant_attachments`: This plugin provides a redundant storage for temporary uploaded attachment files. They are stored in both the database backend as well as on the local file system. It provides also memcache store as a fallback.
    
    - `show_additional_headers`: Proof-of-concept plugin which will fetch additional headers and display them in the message view.
    
    - `squirrelmail_usercopy`: Copy a new users identity and settings from a nearby Squirrelmail installation.
    
    - **`subscriptions_option`**: A plugin which can enable or disable the use of imap subscriptions. It includes a toggle on the settings page under "Server Settings". The preference can also be locked.
    
    - `userinfo`: Sample plugin that adds a new tab to the settings section to display some information about the current user.
    
    - **`vcard_attachments`**: Detects vCard attachments and allows to add them to address book. Also allows to attach vCards of your contacts to composed messages.
    
    - `virtuser_file`: Plugin adds possibility to resolve user email/login according to lookup tables in files.
    
    - `virtuser_query`: Plugin adds possibility to resolve user email/login according to lookup tables in SQL database.
    
    - **`zipdownload`**: Adds an option to download all attachments to a message in one zip file, when a message has multiple attachments. Also allows the download of a selection of messages in one zip file. Supports mbox and maildir format.


Examples
--------

After running the docker containers, login at: http://localhost:8005


### Simplest

Simplest configuration is no configuration:

```bash
docker run -d -p 8005:8080 --name roundcube mwaeckerlin/roundcube
```


### Simple MySQL

Use [mysql] with a persistend volume in a separate container:

```bash
docker run -d --restart unless stopped \
           --name roundcube-mysql-volume \
           mysql \
           sleep infinity
docker run -d --restart unless stopped \
           --name roundcube-mysql \
           --volumes-from roundcube-mysql-volume \
           -e MYSQL_DATABASE=roundcube \
           -e MYSQL_USER=roundcube \
           -e MYSQL_PASSWORD=$(pwgen -s 20 1) \
           -e MYSQL_ROOT_PASSWORD=$(pwgen -s 20 1) \
           mysql
docker run -d --restart unless stopped \
           --name roundcube \
           -p 8005:8080 \
           --link roundcube-mysql:mysql 
           mwaeckerlin/roundcube
```



[Roundcube]: https://roundcube.net "Roundcube homepage"
[mwaeckerlin/roundcube]: https://hub.docker.com/r/mwaeckerlin/roundcube "image on docker hub"
[mwaeckerlin/nginx]: https://hub.docker.com/r/mwaeckerlin/nginx "image on docker hub"
[mwaeckerlin/php-fpm]: https://hub.docker.com/r/mwaeckerlin/php-fpm "image on docker hub"
[mysql]: https://hub.docker.com/_/mysql "image on docker hub"
[PEAR DSN]: http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php "PHP PEAR MDB2 DSN format specification"
