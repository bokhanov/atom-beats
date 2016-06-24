# Using ironSource.atom with Elastic Filebeat Logstash & Docker
[![License][license-image]][license-url]

Atom-filebeat is the way to connect filebeat with ironSource.atom, stand alone or with a Docker container.

- [Signup](https://atom.ironsrc.com/#/signup)
- [Documentation](https://github.com/ironSource/atom-logstash)
- [Example][example-url]

### Send an event to ironSource.Atom using Filebeat

```yaml
############################# Filebeat ######################################
filebeat:
  # List of prospectors to fetch data.
  prospectors:
    # Each - is a prospector. Below are the prospector specific configurations
    -
      paths:
        - /var/log/*.log
        #- c:\programdata\elasticsearch\logs\*
      input_type: log
     
############################# Output ##########################################

# Configure what outputs to use when sending the data collected by the beat.
# Multiple outputs may be used.
output:
  ### Logstash as output
  logstash:
    # The Logstash hosts
    hosts: ["localhost:5044"]
```

__2. Create a file named logstash.conf with following configuration:__
```html
# An input plugin enables a specific source of events to be read by Logstash.
input {

    beats{
    port=>5044
}
}
# filter plugin
filter {  
    fingerprint {
        key => "${AUTH}" #pre-shared auth key from your Atom stream
        method => "SHA256" 
     }
  }

# output plugin
output {
    http {
        url => "http://track.atom-data.io/"
        headers => {
            "x-ironsource-atom-sdk-type" => "atom-beats"
            "x-ironsource-atom-sdk-version" => "${SDK_VERSION:1.0.0}"
        }
        http_method => "post"
        format => "json"
        mapping => {
            "table" => "${STREAM}"
            "data" => "%{message}"
            "auth" => "%{fingerprint}"
        }
        workers => 5
        ssl_certificate_validation => false
    }

}
```

__3. Run logstash__
```bash
STREAM=<the name of your stream> AUTH=<your pre shared auth key> logstash --allow-env -f logstash.conf
```
__4. Run filebeat__
```bash
cd <directory with filebeat>
sudo ./filebeat -e -c <absolute path to directory with filebeat yaml>/filebeat.yml
```

### Send events to ironSource.Atom using Filebeat, Logstash, docker container & docker-compose
__1. Create filebeat.yml with the following content:__
```yaml
############################# Filebeat ######################################
filebeat:
  # List of prospectors to fetch data.
  prospectors:
    # Each - is a prospector. Below are the prospector specific configurations
    -
      paths:
        - /var/log/*.log
        #- c:\programdata\elasticsearch\logs\*
      input_type: log
     
############################# Output ##########################################

# Configure what outputs to use when sending the data collected by the beat.
# Multiple outputs may be used.
output:
  ### Logstash as output
  logstash:
    # The Logstash hosts
    hosts: ["logstash:5044"]
```
__2. Create docker-compose.yml with the following content:__
```yaml
version: '2'
services:
  logstash:
    image: logstash:2.3.1
    entrypoint: bash -c "logstash --allow-env -f /etc/logstash/conf.d/logstash.conf"
    environment:
     STREAM: ${STREAM} # Your Atom Stream
     AUTH: ${AUTH} # Your pre-shared key to Atom Stream
     SDK_VERSION: 1.0.0
    volumes:
    # Specify the logstash.conf file path on your host
    - <absolute path to your logstash.conf file>:/etc/logstash/conf.d/logstash.conf
    # For more options: https://docs.docker.com/compose/compose-file/#volumes-volume-driver

  filebeat:
    image: prima/filebeat:1.2.3
    links: 
    - logstash
    command: bash -c "`sleep 15` ./bin/filebeat (-e -v -d "*") -c /etc/filebeat/filebeat.yml"
    volumes:
    #Specify the filebeat.yml file path on your host
    - <absolute path to yout filebeat.yml  file>:/bin/filebeat.yml
    - /var/log/app-logs:/var/log/log-from-host

 
```

__3. Run docker-compose:__
```bash
STREAM=<the name of your stream> AUTH=<your pre shared auth key> docker-compose up (-d for detached)

OR

export STREAM=<the name of your stream>
export AUTH=<your pre shared auth key> 
docker-compose up -d
```
### Example

You can use our [example][example-url] for sending data to Atom.

### License
MIT

[license-image]: https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square
[license-url]: LICENSE
[example-url]: https://github.com/ironSource/atom-beats/tree/master/example