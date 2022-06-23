FROM debian:jessie

LABEL original="https://github.com/primait/docker-filebeat"
LABEL modifiedby="Volker Scheuber <volker.scheuber@forgerock.com>"
LABEL description="filebeat docker image for ForgeRock Identity Cloud logs"

ENV FILEBEAT_VERSION=7.17.4 \
    FILEBEAT_SHA1=eece85d1007e8f58ccc65ea5bbfcd5c2b733f05a4d9e051f9d75f79dac9678d643b53345be8f1dae95a85118061cd41ce72ce959fdde95f7cb5cd7a853444aff \
    ELASTIC_HOST=bi.scheuber.io \
    ELASTIC_PORT=9200 \
    FIDC_TENANT_NAME= \
    FIDC_TENANT_URL= \
    FIDC_API_KEY_ID= \
    FIDC_API_KEY_SECRET= \
    FIDC_LOG_SOURCES=am-everything,idm-everything \
    FIDC_TAIL_ENABLED=true \
    FIDC_TAIL_INTERVAL=10s \
    FIDC_LOGS_ENABLED=false \
    FIDC_LOGS_INTERVAL=3s \
    FIDC_LOGS_BEGIN_TIME=yyyy-mm-ddThh:mm:ss.ssZ \
    FIDC_LOGS_END_TIME=yyyy-mm-ddThh:mm:ss.ssZ

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
