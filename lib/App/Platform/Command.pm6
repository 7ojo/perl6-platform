use v6;
use App::Platform::Output;
use Terminal::ANSIColor;

class App::Platform::Command is Proc::Async is App::Platform::Output {

    my Str $.prefix = "🐚"; 

    has Str $.out is rw = '';
    has Str $.err is rw = '';
    has Str $.last_line is rw = '';

    submethod TWEAK {
        my $prefix = " {self.after-prefix}";
        self.stdout.tap( -> $str {
            self.out ~= $str;
            for $str.lines {
                if $_ ~~ / Successfully / {
                    put $prefix ~ color('green') ~ $_ ~ color('reset');
                } else {
                    put $prefix ~ $_ ~ color('reset') if $_.chars > 0; 
                }
            }
        });
        self.stderr.tap( -> $str {
            self.err ~= $str;
            for $str.lines {
                if $_ ~~ / ^ (\.|\+)+ $ / {
                    if self.last_line.ends-with('.') or self.last_line.ends-with('+') {
                        print $_;
                    } else {
                        print $prefix ~ color('red') ~ $_;
                    }
                } else {
                    put color('reset') if self.last_line.ends-with('.') or self.last_line.ends-with('+');
                    put $prefix ~ color('red') ~ $_ ~ color('reset') if $_.chars > 0;
                }
                self.last_line = $_ if $_.chars > 0;
            }
        });
    }

    method run(:$cwd = $*CWD) {
        my Str $wrapped-cmd = self.text(self.path ~ ' ' ~ self.args);
        put self.x-prefix ~ color('cyan') ~ $wrapped-cmd.lines.join(color('reset') ~ "\n {self.after-prefix}" ~ color('cyan')) ~ color('reset');
        try sink await self.start :$cwd;
        self;
    }

}
