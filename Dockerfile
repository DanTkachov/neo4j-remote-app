FROM rocker/shiny
LABEL authors="dantk"
# docker build -t neo4j-shiny-test2 . && docker run -it -p 3838:3838 -p 7474:7474 -p 7687:7687 -p 7473:7473 neo4j-shiny-test2

RUN apt-get update
RUN apt-get install -y wget unzip curl lynx make vim gcc gfortran gnupg r-base openjdk-17-jdk software-properties-common lsb-release ssh net-tools
RUN apt-get update
RUN apt-get install openssl

RUN R -e 'install.packages(c("shiny", "neo4r", "visNetwork","magrittr", "neo4jshell", "base64enc", "httr", "jsonlite"))'

RUN wget https://debian.neo4j.com/neotechnology.gpg.key -O neo4j.gpg
RUN apt-key add neo4j.gpg
RUN rm neo4j.gpg
RUN echo 'deb https://debian.neo4j.com stable 5' | tee -a /etc/apt/sources.list.d/neo4j.list

RUN apt-get update
RUN apt-get install -y neo4j=1:5.10.0

COPY ./*.csv /var/lib/neo4j/import/
COPY ./neo4j-plugins/neo4j-graph-data-science-2.4.3.jar /var/lib/neo4j/plugins
ENV NEO4J_dbms_security_procedures_unrestricted=gds.*
RUN echo "server.default_advertised_address=127.0.0.1" >> /etc/neo4j/neo4j.conf
RUN echo "server.bolt.listen_address=0.0.0.0:7687" >> /etc/neo4j/neo4j.conf
RUN echo "server.http.listen_address=0.0.0.0:7474" >> /etc/neo4j/neo4j.conf
RUN echo "server.https.listen_address=0.0.0.0:7473" >> /etc/neo4j/neo4j.conf
RUN echo "dbms.security.auth_enabled=false" >> /etc/neo4j/neo4j.conf

ENV NEO4J_AUTH=none
RUN chmod -R 755 /var/lib/neo4j/import /var/lib/neo4j/plugins


EXPOSE 3838 7474 7687 7473

# GENERATE CERTIFICATE FOR ENCRYPTED NEO4J CONNECTION
# SEE https://neo4j.com/docs/operations-manual/current/security/ssl-framework/#ssl-configuration
#RUN mkdir /certs && \
#    openssl req -x509 -newkey rsa:4096 -keyout /certs/key.pem -out /certs/cert.pem -days 365 -nodes -subj "/C=US/ST=California/L=San Francisco/O=My Company/CN=localhost"
COPY ./certs /certs
RUN mkdir /var/lib/neo4j/certificates/bolt
RUN mkdir /var/lib/neo4j/certificates/bolt/trusted
RUN mkdir /var/lib/neo4j/certificates/bolt/revoked
RUN cp /certs/key.pem var/lib/neo4j/certificates/bolt/private.key
RUN cp /certs/cert.pem var/lib/neo4j/certificates/bolt/public.crt
RUN cp /certs/cert.pem var/lib/neo4j/certificates/bolt/trusted/public.crt

RUN chmod -R 755 /var/lib/neo4j/certificates/bolt
RUN chmod -R 644 /var/lib/neo4j/certificates/bolt/public.crt
RUN chmod -R 400 /var/lib/neo4j/certificates/bolt/private.key
RUN chmod -R 755 /var/lib/neo4j/certificates/bolt/trusted
RUN chmod -R 644 /var/lib/neo4j/certificates/bolt/trusted/public.crt
RUN chmod  -R 755 /var/lib/neo4j/certificates/bolt/revoked

RUN mkdir /var/lib/neo4j/certificates/https
RUN mkdir /var/lib/neo4j/certificates/https/trusted
RUN mkdir /var/lib/neo4j/certificates/https/revoked
RUN cp /certs/key.pem var/lib/neo4j/certificates/https/private.key
RUN cp /certs/cert.pem var/lib/neo4j/certificates/https/public.crt
RUN cp /certs/cert.pem var/lib/neo4j/certificates/https/trusted/public.crt

RUN chmod -R 755 /var/lib/neo4j/certificates/https
RUN chmod -R 644 /var/lib/neo4j/certificates/https/public.crt
RUN chmod -R 400 /var/lib/neo4j/certificates/https/private.key
RUN chmod -R 755 /var/lib/neo4j/certificates/https/trusted
RUN chmod -R 644 /var/lib/neo4j/certificates/https/trusted/public.crt
RUN chmod  -R 755 /var/lib/neo4j/certificates/https/revoked



COPY ./neo4j-local.conf /etc/neo4j/neo4j.conf
COPY ./shiny_app /srv/shiny-server/shiny_app/
COPY ./start.sh /start.sh
COPY ./shiny-server.conf /etc/shiny-server/

CMD ["/start.sh"]