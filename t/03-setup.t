use v6.c;
use lib 't/lib';
use Test;
use Template;

plan 5;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

if not AUTHOR {
     skip-rest "Skipping author test";
     exit;
}

my $tmpdir = $*TMPDIR ~ '/test-docker-platform-10-setup';
mkdir $tmpdir;

ok $tmpdir.IO.e, "got $tmpdir";

{ # Setup project files for project-butterfly
    my %project-butterfly =
        title => "Project \c[BUTTERFLY]",
        name => "project-butterfly"
    ;
    mkdir "$tmpdir/project-butterfly/docker";
    spurt "$tmpdir/project-butterfly/docker/Dockerfile", docker-dockerfile(%project-butterfly);
    my $project-yml = q:heredoc/END/;
    command: nginx -g 'daemon off;'
    volumes:
        - html:/usr/share/nginx/html:ro
    END
    spurt "$tmpdir/project-butterfly/docker/project.yml", $project-yml;
    mkdir "$tmpdir/project-butterfly/html";
    spurt "$tmpdir/project-butterfly/html/index.html", html-welcome(%project-butterfly);
}

subtest 'platform create', {
    plan 2;
    my $proc = run <bin/platform>, "--data-path=$tmpdir/.platform", <create>, :out;
    my $out = $proc.out.slurp-rest;
    ok $out ~~ / DNS \s+ \[ \✔ \] /, 'service dns is up';
    ok $out ~~ / Proxy \s+ \[ \✔ \] /, 'service proxy is up';
}

subtest 'platform ssl genrsa', {
    plan 4;
    my $proc = run <bin/platform>, "--data-path=$tmpdir/.platform", <ssl genrsa>, :out, :err;
    my $out = $proc.out.slurp-rest;
    my $err = $proc.err.slurp-rest;

    ok "$tmpdir/.platform/local".IO.e, '<data>/local exists';
    ok "$tmpdir/.platform/local/ssl".IO.e, '<data>/local/ssl exists';
    for <server-key.key server-key.crt> -> $file {
        ok "$tmpdir/.platform/local/ssl/$file".IO.e, "<data>/local/ssl/$file exists";
    }
}

subtest 'platform ssh keygen', {
    plan 3;
    run <bin/platform>, "--data-path=$tmpdir/.platform", <ssh keygen>;
    ok "$tmpdir/.platform/local/ssh".IO.e, '<data>/local/ssh exists';
    ok "$tmpdir/.platform/local/ssh/$_".IO.e, "<data>/local/ssh/$_ exists" for <id_rsa id_rsa.pub>;
}

subtest 'platform run|stop|start|rm project-butterfly', {
    plan 4;
    my $proc = run <bin/platform>, "--project=$tmpdir/project-butterfly", "--data-path=$tmpdir/.platform", <run>, :out;
    ok $proc.out.slurp-rest.Str ~~ / butterfly \s+ \[ \✔ \] /, 'project butterfly is up';

    sleep 1.5; # project to start

    $proc = run <host project-butterfly.local localhost>, :out;
    my $out = $proc.out.slurp-rest;
    my $found = $out.lines[*-1] ~~ / address \s $<ip-address> = [ \d+\.\d+\.\d+\.\d+ ] $$ /;
    ok $found, 'got ip-address ' ~ ($found ?? $/.hash<ip-address> !! '');

    run <bin/platform>, "--project=$tmpdir/project-butterfly", "--data-path=$tmpdir/.platform", <stop>;

    $proc = run <bin/platform>, "--project=$tmpdir/project-butterfly", "--data-path=$tmpdir/.platform", <start>, :out;
    ok $proc.out.slurp-rest ~~ / butterfly \s+ \[ \✔ \] /, 'project butterfly is up';

    run <bin/platform>, "--project=$tmpdir/project-butterfly", "--data-path=$tmpdir/.platform", <stop>;

    run <bin/platform>, "--project=$tmpdir/project-butterfly", "--data-path=$tmpdir/.platform", <rm>;

    $proc = run <bin/platform>, "--project=$tmpdir/project-butterfly", "--data-path=$tmpdir/.platform", <rm>, :out;
    ok $proc.out.slurp-rest.Str ~~ / No \s such \s container /, 'got error message'
}

# $proc.out.close;
#say $proc.out.slurp-rest;

# TODO: docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy

# Start project
# TODO: run <bin/platform start>, $tmpdir/project-butterfly
# TODO: run <bin/platform start>, $tmpdir/*

# Platform project-snail
#mkdir "$tmpdir/project-snail/docker";
#spurt "$tmpdir/project-snail/docker/Makefile", docker-makefile("Project \c[SNAIL]");

run <bin/platform destroy>;

run <rm -rf>, $tmpdir;
# say $tmpdir;
