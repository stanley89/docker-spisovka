FROM debian:jessie
RUN apt-get -y update
RUN apt-get install -y apache2 php5 php5-gd php-xml-parser php5-intl php5-mysql php5-curl bzip2 wget vim openssl ssl-cert sharutils php5-imap git
RUN mkdir /etc/apache2/ssl
ADD resources/001-spisovka.conf /etc/apache2/sites-available/
ADD resources/start.sh /start.sh
RUN chmod u+x /start.sh
RUN a2enmod rewrite ssl
RUN a2ensite 001-spisovka.conf
CMD ./start.sh
