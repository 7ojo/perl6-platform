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

        { # PHASE: add users to image if any
            my @cmds;
            my $variant = "$dockerfile-path/Dockerfile".IO.slurp ~~ / ^ FROM \s .* alpine / ?? 'alpine' !! 'debian';
            my $shell = $variant eq 'alpine' ?? 'ash -c' !! 'bash -c';
            for $config<users>.Hash.kv -> $login, %params {
                if %params<home> {
                    @cmds.push: 'mkdir -p ' ~ %params<home>.IO.dirname;
                }
                my @cmd = [ 'adduser' ];
                if $variant eq 'alpine' {
                    @cmd.push: "-h {%params<home>}" if %params<home>;
                    @cmd.push: "-g \"{%params<gecos>}\"" if %params<gecos>;
                    @cmd.push: '-S' if %params<system>;
                    @cmd.push: '-D' if not %params<password>;
                    @cmd.push: $login;
                    @cmds.push: @cmd.join(' ');
                } else {
                    @cmd.push: "--home {%params<home>}" if %params<home>;
                    @cmd.push: "--gecos \"{%params<gecos>}\"" if %params<gecos>;
                    @cmd.push: '--system' if %params<system>;
                    @cmd.push: '--disabled-password' if not %params<password>;
                    @cmd.push: '--quiet';
                    @cmd.push: $login;
                    @cmds.push: @cmd.join(' ');
                }
            }
            my $proc = shell "docker run --name {self.name} {self.name} {$shell} '{@cmds.join(' ; ')}'", :out, :err;
            my $out = $proc.out.slurp-rest;
            $proc = run <docker commit>, self.name, self.name, :out;
            $out = $proc.out.slurp-rest;
            $proc = run <docker rm>, self.name, :out;
            $out = $proc.out.slurp-rest;
        } if $config<users>;
        
        # Extra parameters
        my @extra-args;

        # Volume mapping
        my @volumes = map { '--volume ' ~ self.project.IO.abspath ~ '/' ~ $_ }, $config<volumes>.Array;

        { # PHASE: create files to host and mount them inside container
            if $config<ssh> {
                my $path = self.data-path ~ '/' ~ self.domain ~ "/ssh";
                for $config<ssh>.Hash.kv -> $target, $content is rw {
                    if not $path.IO.e {
                        put "No SSH keys available. Maybe you should run:\n\n  platform --data-path={self.data-path} --domain={self.domain} ssh keygen\n";
                        exit;
                    }
                    my ($owner, $group);
                    if $content ~~ Hash {
                        $owner = $content<owner> if $content<owner>;
                        $group = $content<group> if $content<group>;
                        $content = $content<content>;
                    }
                    if "$path/$content".IO.e {
                        run <docker run --name>, self.name, self.name, 'mkdir', $target.IO.dirname; 
                        run <docker cp>, "$path/$content", self.name ~ ":$target";
                        run <docker commit>, self.name, self.name;
                        run <docker rm>, self.name;

                        if $owner and $group {
                            run <docker run --name>, self.name, self.name, 'chown', '-R', "$owner:$group", $target.IO.dirname;
                            run <docker commit>, self.name, self.name;
                            run <docker rm>, self.name;
                        }

                        run <docker run --name>, self.name, self.name, 'chmod', '-R', 'go-rwx', $target.IO.dirname;
                        run <docker commit>, self.name, self.name;
                        run <docker rm>, self.name;
                    }
                    
                }
            }
            for <sudoers files> -> $group {
                for $config{$group}.Hash.kv -> $target, $content is rw {
                    my $path = self.data-path ~ '/' ~ self.domain ~ "/$group";
                    my Str $flags = '';
                    if $content ~~ Hash {
                        $flags ~= ':ro' if $content<readonly>;
                        $content = $content<content>;
                    }
                    if "$path/$content".IO.e {
                        $content = "$path/$content".IO.slurp;
                    }
                    mkdir "$path/{self.name}/" ~ $target.IO.dirname;
                    spurt "$path/{self.name}/{$target}", $content;
                    @volumes.push: "--volume $path/{self.name}/{$target}:{$target}{$flags}";    
                }
            }
        }
        say @volumes; 

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
        self.last-command: shell $cmd, :out, :err;
    }

    method start { self.last-command: run <docker start>, self.name, :out, :err }

    method stop { self.last-command: run <docker stop>, self.name, :out, :err }

    method rm { self.last-command: run <docker rm>, self.name, :out, :err }

}
