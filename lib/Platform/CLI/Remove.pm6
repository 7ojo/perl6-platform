unit module Platform::CLI::Remove;

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
multi cli('remove',
    $path,              #= PATH
    ) is export {
    try {
        CATCH {
            default {
                #say .^name, ': ',.Str;
                #put color('red') ~ "ERROR: $_" ~ color('reset');
                #.Str.say;
                say .^name, do given .backtrace[0] { .file, .line, .subname }
                exit;
                #.throw;
                #cli('remove', :help(True));
            }
        }
        #put '🚩' ~ Platform::Output.after-prefix ~ color('yellow') ~ 'Summary' ~ color('reset');
        if Platform.is-environment($path) {
            say "path: $path\nnetwork: $network\ndomain: $domain\ndata-path: $data-path";
            #my $obj = Platform::Environment(:environment($path), :$network, :$domain, :$data-path).stop;
            my $obj = Platform::Environment(:environment($path), :$data-path).stop;
            $obj.containers[];
            put $obj.rm.as-string;
        } else {
            my $obj = Platform::Project.new(:project($path), :$network, :$domain, :$data-path);
            $obj.stop;
            my $res = $obj.rm;
            put $res.as-string if $res.last-result<err> and $res.last-result<err>.chars > 0;
        }
    }
}

multi cli('remove',
    :h( :help($help) )  #= Print usage
    ) is export {
    CommandLine::Usage.new(
        :name( $*PROGRAM-NAME.IO.basename ),
        :func( &cli ),
        :desc( &cli.candidates[0].WHY.Str ),
        :filter<remove>
        ).parse.say;
}

