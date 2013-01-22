use Test::More qw<no_plan>;
use strict;
use warnings;
use JavaScript::HashRef::Decode qw<decode_js>;

my $str;
my $res;
my $err;

# https://github.com/mfontani/JavaScript-HashRef-Decode/issues/1
$str = "{id:1,oops:,foo:'bar'}";
$res = eval { decode_js($str) };
$err = $@;
ok($err,                    "Dies for invalid input");
ok($err =~ /cannot parse/i, "User-friendly error message when unparsable");
ok($err =~ /\Q$str/i,       "User-friendly error message contains input");
