unit module Platform::CLI::Create;

our $data-path;
our $network;
our $domain;

use Platform::Output;
use Terminal::ANSIColor;
use CommandLine::Usage;

#| Start shared platform services
multi cli('create') is export {
    try {
        CATCH {
            default {
                say $_;
                cli('create', :help(True));
            }
        }
        use Platform;
        put Platform::Output.x-prefix ~ color('yellow') ~ 'Services' ~ color('reset'); 
        put $_.as-string for Platform.new(:$network, :$domain, :$data-path).create.Array;
    }
}

multi cli('create',
    :h( :help($help) )  #= Print usage
    ) is export {
    CommandLine::Usage.new(
        :name( %*ENV<PERL6_PROGRAM_NAME> ),
        :func( &cli ),
        :desc( &cli.candidates[0].WHY.Str ),
        :filter<create>
        ).parse.say;
}
