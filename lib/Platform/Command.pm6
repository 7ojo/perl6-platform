use v6;
use Terminal::ANSIColor;
use Text::Wrap;

class Platform::Command is Proc::Async {

    my Str $.emoji = "🐚"; 

    has Str $.out is rw = '';
    has Str $.err is rw = '';
    has Str $.prefix;

    submethod TWEAK {
        $!prefix = "  : ";
        self.stdout.tap( -> $str {
            self.out ~= $str;
            for $str.lines {
                if $_ ~~ / Successfully / {
                    put $!prefix ~ color('green') ~ $_ ~ color('reset');
                } else {
                    { put $!prefix ~ $_ if $_.chars > 0 } for $str.lines; 
                }
            }
        });
        self.stderr.tap( -> $str {
            self.err ~= $str;
        });
    }

    method run(:$cwd = $*CWD) {
        my Str $wrapped-cmd = wrap-text(self.path ~ ' ' ~ self.args);
        put self.emoji ~ " : " ~ color('cyan') ~ $wrapped-cmd.lines.join("\n  : ") ~ color('reset');
        try sink await self.start(:$cwd);
        self;
    }

}
