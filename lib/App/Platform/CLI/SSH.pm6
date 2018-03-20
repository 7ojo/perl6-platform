unit module App::Platform::CLI::SSH;

our $data-path;
our $network;
our $domain;

use App::Platform::Output;
use Terminal::ANSIColor;
use CommandLine::Usage;
use App::Platform;

#| Wrapper to ssh* commandds
multi cli(
    'ssh',
    :k( :keygen($keygen)) #= Generation of authentication keys
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
        App::Platform.new(:$domain, :$network,:$data-path).ssh('keygen') if $keygen;

        cli('ssh', :help(True)) if ! $keygen;
    }
}

multi cli('ssh',
    :h( :help($help) )  #= Print usage
    ) is export {
    CommandLine::Usage.new(
        :name( %*ENV<PERL6_PROGRAM_NAME> ),
        :func( &cli ),
        :desc( &cli.candidates[0].WHY.Str ),
        :filter<ssh>
        ).parse.say;
}
