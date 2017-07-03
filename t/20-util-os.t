use v6;
use lib 'lib';
use Test;
use Platform::Util::OS;

plan 3;

use-ok 'Platform::Util::OS', 'load Platform::Util::OS';
is Platform::Util::OS.new(:kernel('darwin')).detect(), 'macos', 'macos variant';
ok Platform::Util::OS.detect(),'Platform::Util::OS.detect call';

