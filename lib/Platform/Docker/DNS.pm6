use v6;
use Platform::Container;

class Platform::Docker::DNS is Platform::Container {

    has Str $.name = 'DNS';

    method start {
        my $proc = run
            <docker run -d --rm --name>,
            'platform-' ~ self.name.lc,
            <--publish 53:53/udp --volume /var/run/docker.sock:/var/run/docker.sock:ro --label dns.tld=local --env>,
            "DOMAIN_TLD={self.domain}",
            <zetaron/docker-dns-gen>,
            :out, :err;
        self.last-result = self.result-as-hash($proc);
        self;
    }

    method stop {
        my $proc = run <docker stop -t 0>, 'platform-' ~ self.name.lc, :out, :err;
        self.last-result = self.result-as-hash($proc);
        self;
    }

}
