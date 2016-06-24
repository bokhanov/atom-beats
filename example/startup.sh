STREAM=$STREAM AUTH=$AUTH logstash --allow-env -f logstash.conf &
`sleep 15` ./filebeat -e -d "*" -c filebeat.yml