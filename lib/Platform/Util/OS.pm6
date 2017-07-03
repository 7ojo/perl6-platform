use v6.c;

class Platform::Util::OS {

    has Str $.kernel;

    my Platform::Util::OS $instance;

    method new(*%named) {
        return $instance //= self.bless(|%named);
    }

    submethod detect {
        my Str $v = $instance.kernel ?? $instance.kernel !! $*KERNEL.name;
        given $v {
            when /:i ^ darwin / { return 'macos' }
            when /:i ^ linux / { return 'linux' }
        }
    }

}
