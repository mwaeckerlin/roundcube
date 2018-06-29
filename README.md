Docker Image for Roundcube Webmailer
====================================


Environment Variables
---------------------

Configuration is done using environment variables.


### Database

You have different options to connect to a database. I recommend using [mysql] must have been initialized with the environment variables `MYSQL_PASSWORD`, `MYSQL_USER` and `MYSQL_DATABASE`, which are then inherited and used by [mwaeckerlin/roundcube]


#### MySQL

You can link to a mysql database using `--link your-db-container:mysql`. Here it is important to name the database `mysql` (the text after the colon `:`). Your [mysql] must be initialized with the environment variables below.

Or you can connect to a local MySQL server (e.g. in docker swarm) using the following environment variables:

 - `MYSQL_PASSWORD`: Database password, must be given.
 - `MYSQL_USER`: Database user, defaults to `roundcube`.
 - `MYSQL_DATABASE`: Database name, defaults to `roundcube`.
 
 Database and user must already exist.


#### SQLite

If no database is configured, [mwaeckerlin/roundcube] defaults to SQLite. Do not forget to store the database in a volume an do backups. You can specify the path to the database in variable:

  - `SQLITE_PATH`: Path to the SQLite database file, defaults to `/var/tmp/sqlite.db`.


#### Other Databases

You can specify any database by configuring the following environment variable:

 - `DB_DSNW`: Database connection in [PEAR DSN] format


### IMAP Server

Define which IMAP servers can be accessed by defingen the environment variable:

 - `DEFAULT_HOST`: Defines zero, one or list of IMAP servers, it can be:
 
     - Empty: (default) The login screen provides a text box where you need to enter the IMAP host which you want to connect to.
     
     - One hostname: Exactly this host is connected, you can't choose.
     
     - A comma plus space (`, `) separated list of hosts, presented as combobox (don't use quotes).
    
    Use host prefix `ssl://` or `tls://` to use SSL or TLS connections (strongly recommended).
    
    You can add a name to a hostname by using a space enclodes equal+geater dash (` => `), the name cannot contain a comma.
    
 - `USERNAME_DOMAIN`: Automatically add this domain to user names for login. Only needed for IMAP servers that require full email addresses for login. Specify an array with `host => domain` values to support multiple hosts. Syntax is the the same, as for `DEFAULT_HOST`.


#### Examples

`-e 'DEFAULT_HOST=mail.example.com => Default Server, ssl://webmail.example.com => Webmail Server, ssl://mail.example.com:993 => Secure Webmail Server'` 

`-e 'DEFAULT_HOST='` 

`-e 'DEFAULT_HOST=ssl://mail.example.com'`


Example
-------

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

Then login at: http://localhost:8005


[mysql]: https://hub.docker.com/_/mysql "image on docker hub"
[mwaeckerlin/roundcube]: https://hub.docker.com/r/mwaeckerlin/roundcube "image on docker hub"
[PEAR DSN]: http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php "PHP PEAR MDB2 DSN format specification"
