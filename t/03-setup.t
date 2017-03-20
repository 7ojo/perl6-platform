use v6.c;
use lib 't/lib';
use Test;
use Template;
use nqp;

plan 7;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

if not AUTHOR {
     skip-rest "Skipping author test";
     exit;
}

my $tmpdir = $*TMPDIR ~ '/test-docker-platform-10-setup';
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
command: nginx -g 'daemon off;'
volumes:
    - html:/usr/share/nginx/html:ro
END
    spurt "$project-dir/docker/project.yml", $project-yml;
    mkdir "$project-dir/html";
    spurt "$project-dir/html/index.html", html-welcome(%project);
}

create-project('butterfly');

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

    sleep 1.5; # wait project to start

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

create-project('snail');

subtest 'platform run butterfly|snail', {
    plan 4;
    for <butterfly snail> -> $project {
        my $proc = run <bin/platform>, "--project=$tmpdir/project-$project", "--data-path=$tmpdir/.platform", <run>, :out;
        ok $proc.out.slurp-rest.Str ~~ / $project \s+ \[ \✔ \] /, "project $project is up";
    }

    sleep 1.5; # wait projects to start

    for <butterfly snail> -> $project {
        my $proc = run <host>, 'project-' ~ $project ~ '.local', <localhost>, :out;
        my $out = $proc.out.slurp-rest;
        my $found = $out.lines[*-1] ~~ / address \s $<ip-address> = [ \d+\.\d+\.\d+\.\d+ ] $$ /;
        ok $found, 'got ip-address ' ~ ($found ?? $/.hash<ip-address> !! '') ~ " for $project";
    }
}

# TODO: Sudoers+platorc account setup

# TODO: SSL public key authentication setup

subtest 'platform stop|rm butterfly|snail', {
    plan 2;
    for <butterfly snail> -> $project {
        run <bin/platform>, "--project=$tmpdir/project-$project", "--data-path=$tmpdir/.platform", <stop>;
        run <bin/platform>, "--project=$tmpdir/project-$project", "--data-path=$tmpdir/.platform", <rm>;
        ok 1, "stop+rm for project $project";
    }
}

run <bin/platform destroy>;

