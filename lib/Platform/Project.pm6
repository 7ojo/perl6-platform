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

        # Find Dockerfilie
        my ($dockerfile-path, $projectyml-path);
        for self.project ~ "/docker", self.project {
            $dockerfile-path = $_ if not $dockerfile-path and "$_/Dockerfile".IO.e;
            $projectyml-path = "$_/project.yml" if not $projectyml-path and "$_/project.yml".IO.e;
        }

        my $config = $projectyml-path ?? load-yaml $projectyml-path.IO.slurp !! item(%.defaults);

        # Build docker image
        my $proc = run <docker build -t>, self.name, <.>, :cwd«$dockerfile-path», :out;
        my $out = $proc.out.slurp-rest;

        my $last-line = $out.lines[*-1];
        put $out if not $last-line ~~ / Successfully \s built /;

        # Run docker image
        my @volumes = map { self.project.IO.abspath ~ '/' ~ $_ }, $config<volumes>.Array;
        my $volumes = @volumes.elems > 0 ?? "--volume '" ~ join(" --volume '", @volumes) ~ "'" !! '';

        # TODO: Why run <..> doesn't work? docker needs shell or just doing something wrong?
        self.last-command: shell "docker run --env VIRTUAL_HOST={self.hostname} -detach --interactive=true --tty=true --hostname {self.hostname} --name {self.name} {$volumes} {self.name} {$config<command>}", :out, :err;
    }

    method start { self.last-command: run <docker start>, self.name, :out, :err }

    method stop { self.last-command: run <docker stop>, self.name, :out, :err }

    method rm { self.last-command: run <docker rm>, self.name, :out, :err }

}
