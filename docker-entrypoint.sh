#!/bin/bash

# This creates filebeat configuration file based on environment variables

# set -x
# set -e

cd /opt/filebeat

TEMPLATE_FILE="filebeat.yml.template"
CONFIG_FILE="filebeat.yml"
cat >$TEMPLATE_FILE <<EOF
filebeat.inputs:
- type: httpjson
  config_version: 2
  request.url: ##FIDC_TENANT_URL##/monitoring/logs/tail
  auth.basic:
    user: ##FIDC_API_KEY_ID##
    password: ##FIDC_API_KEY_SECRET##
  request.transforms:
    - set:
        target: url.params.source
		value: '##FIDC_LOG_SOURCES##'
    - set:
        target: url.params._pagedResultsCookie
        value: '[[.last_response.body.pagedResultsCookie]]'
  request.rate_limit:
    limit: '[[.last_response.header.Get "x-ratelimit-limit"]]'
    remaining: '[[.last_response.header.Get "x-ratelimit-remaining"]]'
    reset: '[[.last_response.header.Get "x-ratelimit-reset"]]'
  response.split:
    target: body.result
    type: array
    transforms:
      - set:
          target: body.tenant
          value: '##FIDC_TENANT_URL##'
processors:
  - decode_json_fields:
      fields: ["message"]
      process_array: true
      max_depth: 5
      target: ""
      overwrite_keys: true
      add_error_key: true
  - timestamp:
      field: timestamp
      ignore_failure: false
      layouts:
        - '2006-01-02T15:04:05.999999999Z'
      test:
        - '2021-03-16T16:39:40.410894588Z'
  - drop_fields:
      fields: ["timestamp"]
  - if:
      contains:
        type: "text"
    then:
      - rename:
          fields:
            - from: "payload"
              to: "text_payload"
          ignore_missing: false
          fail_on_error: true
    else:
      - drop_event:
          when:
            equals:
              payload.userId: "id=amadmin,ou=user,ou=am-config"
      - extract_array:
          when:
            has_fields: ['payload.http.request.headers.x-forwarded-for']
          field: payload.http.request.headers.x-forwarded-for
          fail_on_error: false
          ignore_missing: true
          mappings:
            payload.http.request.headers.x-forwarded-for-extracted: 0
      - dissect:
          when:
            has_fields: ['payload.http.request.headers.x-forwarded-for-extracted']
          tokenizer: "%{payload.http.request.client_ip}, %{ip2}, %{ip3}"
          field: "payload.http.request.headers.x-forwarded-for-extracted"
          target_prefix: ""
          ignore_failure: true
          trim_values: all
      - extract_array:
          when:
            has_fields: ['payload.http.request.headers.user-agent']
          field: payload.http.request.headers.user-agent
          fail_on_error: false
          ignore_missing: true
          mappings:
            payload.http.request.headers.user-agent-extracted: 0
      - drop_fields:
          fields: ["ip2", "ip3", "payload.http.request.headers.x-forwarded-for", "payload.http.request.headers.user-agent"]
          ignore_missing: true
      - rename:
          fields:
            - from: "payload"
              to: "json_payload"
          ignore_missing: false
          fail_on_error: true
output.elasticsearch:
  hosts: ["##ELK_HOST##:##ELASTIC_PORT##"]
  pipeline: fidc
setup.template:
  type: "index"
  append_fields:
    - name: json_payload
      type: object
    - name: text_payload
      type: text
    - name: geoip.location
      type: geo_point
EOF

# set values in config file from env vars
sed \
    -e "s@##FIDC_TENANT_URL##@$FIDC_TENANT_URL@g" \
    -e "s@##FIDC_API_KEY_ID##@$FIDC_API_KEY_ID@g" \
    -e "s@##FIDC_API_KEY_SECRET##@$FIDC_API_KEY_SECRET@g" \
    -e "s@##FIDC_LOG_SOURCES##@$FIDC_LOG_SOURCES@g" \
    $TEMPLATE_FILE >>$CONFIG_FILE

#./filebeat -e -c $CONFIG_FILE
#rm -f $CONFIG_FILE

# Add filebeat as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- filebeat "$@"
fi

exec "$@"
