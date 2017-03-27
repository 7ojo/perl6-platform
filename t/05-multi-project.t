use v6.c;
use lib 't/lib';
use Test;
use Template;
use nqp;

plan 6;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

if not AUTHOR {
     skip-rest "Skipping author test";
     exit;
}

my $domain-amazon = 'amazon';
my $domain-sahara = 'sahara';

my $tmpdir = $*TMPDIR ~ '/test-platform-05-multi-project';
run <rm -rf>, $tmpdir if $tmpdir.IO.e;
mkdir $tmpdir;

ok $tmpdir.IO.e, "got $tmpdir";

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
    plan 1;
    ok True, "TODO";
}

#
# Start 3 projects under *.amazon domain with single command and override
# project's default settings
#
subtest "platform .. --environment=amazon.yml run", {
    plan 1;
    ok True, "TODO";
}

run <bin/platform destroy>;
