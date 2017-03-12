use v6;
use Platform::Docker::Service::DNS;
use Text::Wrap;
use YAMLish;

class Platform {

    has Str $.domain;
    has Str $.data-path;
    has Str $.config;
    has Str @.services = 'DNS', 'Proxy';

    multi method start {
        # say @.services;
        say "Platform";
        {
            my $dns = Platform::Docker::Service::DNS.new(:$.domain);
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
        # Find Dockerfilie
        my $dockerfile-path;
        my $projectyml-path;
        for "$project-dir/docker", $project-dir {
            if not $dockerfile-path and "$_/Dockerfile".IO.e {
                $dockerfile-path = $_;
            }
            if not $projectyml-path and "$_/project.yml".IO.e {
                $projectyml-path = "$_/project.yml";
            }
        }
        my $conf = load-yaml $projectyml-path.IO.slurp;

        # Build docker image
        my $proc = run <docker build -t>, $project-name, <.>, :cwd«$dockerfile-path», :out;
        my $out = $proc.out.slurp-rest;

        my $last-line = $out.lines[*-1];
        if not $last-line ~~ / Successfully \s built / {
            say $out;
        }

        # Run docker image
        my $volumes = '';
        if $conf<volumes> {
            my @volumes = map { $project-dir.IO.abspath ~ '/' ~ $_ }, $conf<volumes>.Array;
            $volumes = "--volume '" ~ join(" --volume '", @volumes) ~ "'";
        }
        my $command = $conf<command> ?? $conf<command> !! '/bin/bash';
        # TODO: Why run <..> doesn't work? docker needs shell or just doing something wrong?
        my $hostname = $project-name ~ '.' ~ $.domain;
        $proc = shell "docker run --env VIRTUAL_HOST=$hostname -detach --interactive=true --tty=true --rm --hostname $hostname --name $project-name {$volumes} {$project-name} {$command}", :out;
        $out = $proc.out.slurp-rest;
    }

    multi method stop {
        # say @.services;
        my $dns = Platform::Docker::Service::DNS.new(:$.domain);
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
