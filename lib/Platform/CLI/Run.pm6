unit module Platform::CLI::Run;

our $data-path;
our $network;
our $domain;

use Platform::Output;
use Terminal::ANSIColor;
use CommandLine::Usage;
use Platform;
use Platform::Project;
use Platform::Environment;

#| Initialize single project or environment with collection of projects
multi cli('run',
    $path,              #= PATH
    ) is export {
    try {
        CATCH {
            default {
                put color('red') ~ "ERROR: $_" ~ color('reset');
                cli('run', :help(True));
            }
        }
        #put '🚩' ~ Platform::Output.after-prefix ~ color('yellow') ~ 'Summary' ~ color('reset');
        if Platform.is-environment($path) {
            put Platform::Environment(:environment($path), :$network, :$domain, :$data-path).run.as-string
        } else {
            put Platform::Project.new(:project($path), :$network, :$domain, :$data-path).run.as-string;
        }
    }
}

multi cli('run',
    :h( :help($help) )  #= Print usage
    ) is export {
    CommandLine::Usage.new(
        :name( $*PROGRAM-NAME.IO.basename ),
        :func( &cli ),
        :desc( &cli.candidates[0].WHY.Str ),
        :filter<run>
        ).parse.say;
}

