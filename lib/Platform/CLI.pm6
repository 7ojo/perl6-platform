unit module Platform::CLI;

use Platform::CLI::Attach;
#`(
use Platform::CLI::Create;
use Platform::CLI::Destroy;
use Platform::CLI::Remove;
use Platform::CLI::Rm;
use Platform::CLI::Run;
use Platform::CLI::SSH;
use Platform::CLI::SSL;
use Platform::CLI::Start;
use Platform::CLI::Stop;
)

our $data-path is export(:vars);

multi cli is export {
    OUTER::USAGE();
}

multi set-defaults(
    :D( :debug($debug) ),               #= Enable debug mode
    :$data-path = '$HOME/.platform',    #= Location of resource files
    ) is export {
    set-defaults(
        fallback    => 1,
        debug       => $debug,
        data-path   => $data-path,
        );
}

multi set-defaults(*@args, *%args) {
    for <Attach> -> $module {
        my $class-name = "Platform::CLI::$module";
        for <data-path> -> $class-var {
            if %args{$class-var}:exists {
                my $value = %args{$class-var};
                $value = $value.subst(/ '$HOME' /, $*HOME);
                ::($class-name)::("\$$class-var") = $value;
                %args«$class-var»:delete;
            }
        }
    }
    %args<fallback>:delete;
    %args<debug>:delete;
    %args;
}
