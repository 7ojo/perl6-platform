use v6;

class Platform::Docker::Container {

    has Str $.domain = 'local';

    method result-as-hash($proc) {
        my $out = $proc.out.slurp-rest;
        my $err = $proc.err.slurp-rest;
        my %result =
            ret => $err.chars == 0,
            out => $out,
            err => $err
        ;
    }

}
