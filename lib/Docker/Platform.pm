use v6.c;
use Docker::Platform::Service::DNS;
use Text::Wrap;

class Docker::Platform {

    has Str $.domain;
    has Str $.data-path;
    has Str $.config;
    has Str @.services = 'DNS', 'Proxy';

    multi method start {
        # say @.services;
        say "Platform";
        {
            my $dns = Docker::Platform::Service::DNS.new(:$.domain);
            my %res = $dns.start;
            say sprintf("├─ Service: DNS     [%s]", %res<err>.chars == 0 ?? "\c[heavy check mark]" !! "\c[heavy multiplication x]");
            say "│  └─ " ~ join("\n│     ", wrap-text(%res<err>).lines) if %res<err>.chars > 0;
        }
        say "└─ Service: Proxy   [\c[heavy check mark]]"; #  \c[heavy multiplication x]";
    }

    multi method start(Str $project-dir) {
        my $project-name = $project-dir.IO.basename;
        if not $project-dir.IO.e {
            say "ERROR: Can't read $project-dir directory";
            exit;
        }
        # Find Dockerfile
        my $dockerfile-path;
        for "$project-dir/docker", $project-dir {
            if "$_/Dockerfile".IO.e {
                $dockerfile-path = $_;
                last;
            }
        }
        # Build docker image
        my $proc = run <docker build -t>, $project-name, <.>, :cwd«$dockerfile-path», :out;
        my $out = $proc.out.slurp-rest;

        my $last-line = $out.lines[*-1];
        if not $last-line ~~ / Successfully \s built / {
            say $out;
        }

        # Run docker image
        # TODO: Specify volumes somewhere
        my $volume = 'html:/usr/share/nginx/html:ro';
        $volume = $project-dir.IO.abspath ~ "/$volume";
        # TODO: Specify custom command somewhere
        my $command = "nginx -g 'daemon off;'";

        # TODO: Why run <..> doesn't work? docker needs shell?
        my $hostname = $project-name ~ '.' ~ $.domain;
        $proc = shell "docker run --env VIRTUAL_HOST=$hostname -detach --interactive=true --tty=true --rm --hostname $hostname --name $project-name --volume '$volume' $project-name $command", :out;
        $out = $proc.out.slurp-rest;
    }

    multi method stop {
        # say @.services;
        my $dns = Docker::Platform::Service::DNS.new(:$.domain);
        my %res = $dns.stop;
    }

    multi method stop(Str $project-dir) {
        my $project-name = $project-dir.IO.basename;
        my $proc = run <docker stop -t 0>, $project-name, :out;
        my $out = $proc.out.slurp-rest;
    }

    method ssl('genrsa') {
        my $ssl-dir = $.data-path ~ '/ssl';
        if not $ssl-dir.IO.e {
            mkdir $ssl-dir;
        }
        run <openssl genrsa -out>, "$ssl-dir/server-key.key", <4096>;
        run <openssl rsa -in>, "$ssl-dir/server-key.key", <-out>, "$ssl-dir/server-key.crt";
    }

    method ssh('keygen') {
        my $ssh-dir = $.data-path ~ '/ssh';
        if not $ssh-dir.IO.e {
            mkdir $ssh-dir;
        }
        # TODO: Why I can't get this work with run <..>?
        shell "ssh-keygen -t rsa -q -N '' -f $ssh-dir/id_rsa";
    }

    submethod TWEAK {
        # Create data-pathuration path
        $!data-path .= subst(/\~/, $*HOME);
        $!data-path ~= '/' ~ $!domain;
        if not $!data-path.IO.e {
            mkdir $!data-path;
        }
    }

}
