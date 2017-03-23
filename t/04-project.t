use v6.c;
use lib 't/lib';
use Test;
use Template;
use nqp;

plan 4;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

if not AUTHOR {
     skip-rest "Skipping author test";
     exit;
}

my $tmpdir = $*TMPDIR ~ '/test-platform-04-project';
run <rm -rf>, $tmpdir if $tmpdir.IO.e;
mkdir $tmpdir;

ok $tmpdir.IO.e, "got $tmpdir";

sub create-project(Str $animal) {
    my $project-dir = $tmpdir ~ "/project-" ~ $animal.lc;
    my %project =
        title => "Project " ~ nqp::getstrfromname($animal.uc),
        name => "project-" ~ $animal.lc
    ;
    mkdir "$project-dir/docker";
    spurt "$project-dir/docker/Dockerfile", docker-dockerfile(%project);
    my $project-yml = q:heredoc/END/;
        # command: nginx -g 'daemon off;'
        # volumes:
        #     - html:/usr/share/nginx/html:ro
        type: systemd
        command: /sbin/init
        environment:
          - GIT_BRANCH=$(GIT_BRANCH)
        build:
          - build-arg SYSTEMD=0
        volumes:
          # <from>:<to> if <from> is empty, defaults to root e.g. '.'
          - :/var/www/app
          - html:/usr/share/nginx/local:ro
        users:
          platorc:
            system: true
            home: /var/lib/auth/platorc
        ssh:
          # <target>: <content>
          /var/lib/auth/platorc/.ssh/authorized_keys:
            content: id_rsa.pub
            owner: platorc
            group: nobody
        sudoers:
          # <target>: <content>
          /etc/sudoers.d/app-installer: |
            platorc ALL=(www-data:www-data) NOPASSWD: /var/www/app/bin/installer
        files:
          # <target>: <content>
          /var/www/app/config:
            readonly: true
            content: |
              <?php
              $hello = "こんにちは!";
          /etc/install.ini: |
            foo
            bar
            kaa
          /etc/foo/bar/config.ini: |
            [default]
            host = project-honeybee.local
            
            [ui.project-honeybee.local]
            path = /var/www/app/ui
        END
    spurt "$project-dir/docker/project.yml", $project-yml;
    mkdir "$project-dir/html";
    spurt "$project-dir/html/index.html", html-welcome(%project);
    spurt "$project-dir/config", '<?php $hello = "Hello world!"';
}

create-project('honeybee');

subtest 'platform create', {
    plan 2;
    my $proc = run <bin/platform>, "--data-path=$tmpdir/.platform", <create>, :out;
    my $out = $proc.out.slurp-rest;
    ok $out ~~ / DNS \s+ \[ \✔ \] /, 'service dns is up';
    ok $out ~~ / Proxy \s+ \[ \✔ \] /, 'service proxy is up';
}

subtest 'platform run', {
    plan 2;
    my $proc = run <bin/platform>, "--project=$tmpdir/project-honeybee", "--data-path=$tmpdir/.platform", <run>, :out;
    ok $proc.out.slurp-rest.Str ~~ / honeybee \s+ \[ \✔ \] /, 'project honeybee is up';

    sleep 1.5; # wait project to start

    $proc = run <host project-honeybee.local localhost>, :out;
    my $out = $proc.out.slurp-rest;
    my $found = $out.lines[*-1] ~~ / address \s $<ip-address> = [ \d+\.\d+\.\d+\.\d+ ] $$ /;
    ok $found, 'got ip-address ' ~ ($found ?? $/.hash<ip-address> !! '');
}


subtest 'platform stop|rm honeybee', {
    plan 1;
    for <honeybee> -> $project {
        run <bin/platform>, "--project=$tmpdir/project-$project", "--data-path=$tmpdir/.platform", <stop>;
        run <bin/platform>, "--project=$tmpdir/project-$project", "--data-path=$tmpdir/.platform", <rm>;
        ok 1, "stop+rm for project $project";
    }
}

run <bin/platform destroy>;

