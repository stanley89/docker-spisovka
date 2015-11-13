#!/bin/bash
if [ ! -f /etc/apache2/ssl/server.key ]; then
        mkdir -p /etc/apache2/ssl
        KEY=/etc/apache2/ssl/apache.key
        DOMAIN=$(hostname)
        export PASSPHRASE=$(head -c 128 /dev/urandom  | uuencode - | grep -v "^end" | tr "\n" "d")
        SUBJ="
C=CZ
ST=Czech Republic
O=Pirati
localityName=Prague
commonName=$DOMAIN
organizationalUnitName=
emailAddress=webmaster@$DOMAIN
"
        openssl genrsa -des3 -out /etc/apache2/ssl/apache.key -passout env:PASSPHRASE 2048
        openssl req -new -batch -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key $KEY -out /tmp/$DOMAIN.csr -passin env:PASSPHRASE
        cp $KEY $KEY.orig
        openssl rsa -in $KEY.orig -out $KEY -passin env:PASSPHRASE
        openssl x509 -req -days 365 -in /tmp/$DOMAIN.csr -signkey $KEY -out /etc/apache2/ssl/apache.crt
fi

if [ -f /.firstrun ]; then
	git clone git://git.blue-point.cz/spisovka.git /var/www/spisovka
	cd /var/www/spisovka
	git checkout tags/3.4.1
	echo > /var/www/spisovka/client/configs/system.ini << EOF
database.driver = mysql          ; databazovy zdroj (aktualne pouze mysql)
database.host = $MYSQL_PORT_3306_TCP_ADDR        ; adresa serveru
database.username = $MYSQL_ENV_DB_USER             ; prihlasovaci jmeno k databazi
database.password = $MYSQL_ENV_DB_PASS             ; prihlasovaci heslo k databazi
database.database = $MYSQL_ENV_DB_NAME             ; databaze (musi existovat !!!)
database.charset  = utf8         ; kodovani databaze
database.prefix  =               ; prefix tabulek ( priklad: "s3_". Pouzijte, pokud v databazi jiz existuje aplikace spisovky nebo jakekoli jine tabulky)
database.profiler = TRUE         ; povoluje profilovani - zaznamenani pouzitych SQL dotazu
EOF
	chown www-data /var/www/spisovka/client /var/www/spisovka/log -R
	mv /var/www/spisovka/index.ph /var/www/spisovka/index.php
	php /system.docker.ph > /var/www/spisovka/client/configs/system.ini
	rm /.firstrun
fi

#HOSTLINE=$(echo $(ip -f inet addr show eth0 | grep 'inet' | awk '{ print $2 }' | cut -d/ -f1) $(hostname) $(hostname -s))
#echo $HOSTLINE >> /etc/hosts
/usr/sbin/apache2ctl -D FOREGROUND
