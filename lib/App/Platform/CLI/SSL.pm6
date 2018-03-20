unit module App::Platform::CLI::SSL;

our $data-path;
our $network;
our $domain;

use App::Platform::Output;
use Terminal::ANSIColor;
use CommandLine::Usage;
use App::Platform;

#| Wrapper to openssl command
multi cli(
    'ssl',
    :g( :genrsa($genrsa)), #= Generation of RSA Private Key
    ) is export {
    try {
        CATCH {
            default {
                #.Str.say;
                # say .^name, do given .backtrace[0] { .file, .line, .subname }
                put color('red') ~ "ERROR: $_" ~ color('reset');
                exit;
            }
        }
        App::Platform.new(:$domain, :$network,:$data-path).ssl('genrsa') if $genrsa;
        cli('ssl', :help(True)) if ! $genrsa;
    }
}

multi cli(
    'ssl',
    :h( :help($help) )  #= Print usage
    ) is export {
    CommandLine::Usage.new(
        :name( %*ENV<PERL6_PROGRAM_NAME> ),
        :func( &cli ),
        :desc( &cli.candidates[0].WHY.Str ),
        :filter<ssl>
        ).parse.say;
}
