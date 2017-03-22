use v6;
use Platform::Container;
use YAMLish;

class Platform::Project is Platform::Container {

    has %.defaults =
        command => '/bin/bash',
        volumes => []
        ;

    submethod BUILD {
        die "ERROR: Can't read {self.project} directory" if not self.project.IO.e;
        self.name = self.project.IO.basename;
        self.hostname = self.name ~ '.' ~ self.domain;
    }

    method run {

        my ($config, $dockerfile-path, $projectyml-path);

        { # PHASE: Find Dockerfile
            for self.project ~ "/docker", self.project {
                $dockerfile-path = $_ if not $dockerfile-path and "$_/Dockerfile".IO.e;
                $projectyml-path = "$_/project.yml" if not $projectyml-path and "$_/project.yml".IO.e;
            }
            $config = $projectyml-path ?? load-yaml $projectyml-path.IO.slurp !! item(%.defaults);
        }

        { # PHASE: build
            my @args;
            if $config<build> {
                for $config<build>.Array {
                    next if $_.Str.chars == 0;
                    my ($option, $value) = $_.split(' ');
                    @args.push("--$option");
                    @args.push($value) if $value.chars > 0;
                }
            }
            my $proc = run <docker build -t>, self.name, @args, <.>, :cwd«$dockerfile-path», :out;
            my $out = $proc.out.slurp-rest;

            my $last-line = $out.lines[*-1];
            put $out if not $last-line ~~ / Successfully \s built /;
        }

        # Extra parameters
        my @extra-args;

        # Volume mapping
        my @volumes = map { '--volume ' ~ self.project.IO.abspath ~ '/' ~ $_ }, $config<volumes>.Array;

        # Type of docker image e.g systemd
        if $config<type> and $config<type> eq 'systemd' {
            @volumes.push('--volume /sys/fs/cgroup:/sys/fs/cgroup');
            @extra-args.push('--privileged');
        }

        # Environment variables
        my @env = [ "--env VIRTUAL_HOST={self.hostname}" ];
        if $config<environment> {
            my $proc = run <git -C>, self.project, <rev-parse --abbrev-ref HEAD>, :out, :err;
            my $branch = $proc.out.slurp-rest.trim;
            @env = (@env, map { $_ = '--env ' ~ $_.subst(/ \$\(GIT_BRANCH\) /, $branch) }, $config<environment>.Array).flat;
        }

        # PHASE: run
        my @args = flat @env, @volumes, @extra-args;
        my $cmd = "docker run -dit -h {self.hostname} --name {self.name} {@args.join(' ')} {self.name} {$config<command>}";
        say $cmd;
        self.last-command: shell $cmd, :out, :err;
    }

    method start { self.last-command: run <docker start>, self.name, :out, :err }

    method stop { self.last-command: run <docker stop>, self.name, :out, :err }

    method rm { self.last-command: run <docker rm>, self.name, :out, :err }

}
