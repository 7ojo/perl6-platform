use v6.c;
use Docker::Platform::Container;

class Docker::Platform::Service::DNS is Docker::Platform::Container {

    has Str $.name = 'platform-dns';

    method start {
        my $proc = run
            <docker run -d --rm --name>,
            $.name,
            <--publish 53:53/udp --volume /var/run/docker.sock:/var/run/docker.sock:ro --label dns.tld=local --env>,
            "DOMAIN_TLD={$.domain}",
            <zetaron/docker-dns-gen>,
            :out, :err;
        self.result-as-hash($proc);
    }

    method stop {
        my $proc = run <docker stop -t 0>, $.name, :out, :err;
        self.result-as-hash($proc);
    }

}
