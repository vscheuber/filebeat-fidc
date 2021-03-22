FROM debian:jessie

LABEL original="https://github.com/primait/docker-filebeat"
LABEL modifiedby="Volker Scheuber <volker.scheuber@forgerock.com>"
LABEL description="filebeat docker image for ForgeRock Identity Cloud logs"

ENV FILEBEAT_VERSION=7.11.2 \
    FILEBEAT_SHA1=d00eb13b12b0a271d10598b6aaee7c11ff2e8d3db42f6a7404eeb0e93af2751882d47c5a6735d2bee0ccb3267de9574970487d6167d0830794f5597fcd6cad94 \
    ELASTIC_HOST= \
    ELASTIC_PORT= \
    FIDC_TENANT_NAME= \
    FIDC_TENANT_URL= \
    FIDC_API_KEY_ID= \
    FIDC_API_KEY_SECRET= \
    FIDC_LOG_SOURCES=

RUN set -x && \
  apt-get update && \
  apt-get install -y wget curl vim nmap net-tools && \
  wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz -O /opt/filebeat.tar.gz && \
  cd /opt && \
  echo "${FILEBEAT_SHA1} filebeat.tar.gz" | sha512sum -c - && \
  tar xzvf filebeat.tar.gz && \
  cd /opt && \
  mv filebeat-${FILEBEAT_VERSION}-linux-x86_64 filebeat && \
  apt-get purge -y wget && \
  apt-get autoremove -y && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [ "/opt/filebeat/filebeat", "-e", "-c", "/opt/filebeat/filebeat.yml" ]
