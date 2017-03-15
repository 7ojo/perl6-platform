# Platform Project Development

Tool for managing and running single projects or tightly coupled projects via Docker environment. In a long run aims to be kind of swiss army knife for configuring different like development environments.

# Features

* Auto configuring DNS server [1]
* Auto configuring HTTP proxy server [2]
* Generation and usage of SSL RSA keys
* Generation and usage of SSH authentication keys
* Sudoers file configuration
* Starting and stopping projects with project specific configuration
* Support for basic docker containers and more cumbersome systemd containers

# Synopsis

    $ platform ssl genrsa
    $ platform ssh keygen
    $ platform create
    $ platform --environment my-projects.yml run|start|stop|rm
    $ platform --project=butterfly-project/ run|start|stop|rm
    $ platform destroy

# References

1. [zetaron/docker-dns-gen](//github.com/zetaron/docker-dns-gen)
2. [jwilder/docker-gen](//github.com/jwilder/docker-gen)
