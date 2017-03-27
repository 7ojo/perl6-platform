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

my $tmpdir = $*TMPDIR ~ '/test-platform-05-environment';
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

my $domain-amazon = 'amazon';
my $domain-sahara = 'sahara';

#
# General setup
#
subtest 'platform create', {
    plan 2;
    my $proc = run <bin/platform>, "--data-path=$tmpdir/.platform", <create>, :out;
    my $out = $proc.out.slurp-rest;
    ok $out ~~ / DNS \s+ \[ \✔ \] /, 'service dns is up';
    ok $out ~~ / Proxy \s+ \[ \✔ \] /, 'service proxy is up';
}

subtest "platform --domain=$domain-sahara ssh keygen", {
    plan 3;
    run <bin/platform>, "--domain=$domain-sahara", "--data-path=$tmpdir/.platform", <ssh keygen>;
    ok "$tmpdir/.platform/$domain-sahara/ssh".IO.e, "<data>/$domain-sahara/ssh exists";
    ok "$tmpdir/.platform/$domain-sahara/ssh/$_".IO.e, "<data>/$domain-sahara/ssh/$_ exists" for <id_rsa id_rsa.pub>;
}

subtest "platform --domain=$domain-amazon ssh keygen", {
    plan 3;
    run <bin/platform>, "--domain=$domain-amazon", "--data-path=$tmpdir/.platform", <ssh keygen>;
    ok "$tmpdir/.platform/$domain-amazon/ssh".IO.e, "<data>/$domain-amazon/ssh exists";
    ok "$tmpdir/.platform/$domain-amazon/ssh/$_".IO.e, "<data>/$domain-amazon/ssh/$_ exists" for <id_rsa id_rsa.pub>;
}

#
# Start 2 projects under *.sahara domain with single command and project's 
# default settings
#
subtest "platform .. --environment=sahara.yml run", {
    plan 4;

    create-project('scorpion');
    create-project('ant');

    my $environment-yml = q:heredoc/END/;
        project-scorpion: true
        project-ant: true
        END

    spurt "$tmpdir/sahara.yml", $environment-yml;

    my $proc = run <bin/platform>, "--domain=sahara", "--environment=$tmpdir/sahara.yml", "--data-path=$tmpdir/.platform", <run>, :out;
    my $out = $proc.out.slurp-rest;
    ok $out ~~ / project\-scorpion \s+ \[ \✔ \] /, "project-scorpion run";
    ok $out ~~ / project\-ant \s+ \[ \✔ \] /, "project-ant run";

    sleep 1.5;

    for <scorpion ant> -> $project {
        $proc = run <host>, "project-{$project}.sahara", <localhost>, :out;
        $out = $proc.out.slurp-rest;
        my $found = $out.lines[*-1] ~~ / address \s $<ip-address> = [ \d+\.\d+\.\d+\.\d+ ] $$ /;
        ok $found, "got project-$project.sahara ip-address " ~ ($found ?? $/.hash<ip-address> !! '');
    }
}

#
# Start 3 projects under *.amazon domain with single command and override
# project's default settings
#
subtest "platform .. --environment=amazon.yml run", {
    plan 1;
    ok True, "TODO";
}

subtest "platform .. --environment=shara.yml stop|rm", {
    plan 4;
    my $proc = run <bin/platform>, "--environment=$tmpdir/sahara.yml", "--data-path=$tmpdir/.platform", <stop>, :out;
    my $out = $proc.out.slurp-rest;
    ok $out ~~ / project\-scorpion \s+ \[ \✔ \] /, 'project-scorpion stop';
    ok $out ~~ / project\-ant \s+ \[ \✔ \] /, 'project-ant stop';
    $proc = run <bin/platform>, "--environment=$tmpdir/sahara.yml", "--data-path=$tmpdir/.platform", <rm>, :out;
    $out = $proc.out.slurp-rest;
    ok $out ~~ / project\-scorpion \s+ \[ \✔ \] /, 'project-scorpion rm';
    ok $out ~~ / project\-ant \s+ \[ \✔ \] /, 'project-ant rm';
}

run <bin/platform destroy>;
