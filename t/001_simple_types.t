use Test::More qw<no_plan>;
use strict;
use warnings;

# This uses the JavaScript::HashRef::Decode **INTERNALS**

use_ok('JavaScript::HashRef::Decode');

my $parser = do {
    no warnings 'once';
    Parse::RecDescent->new($JavaScript::HashRef::Decode::js_grammar)
        or die "Parse::RecDescent: Bad JS grammar!\n";
};

my $str;
my $res;

$str = 'undefined';
$res = $parser->undefined($str);
$res = $res->out;
is($res, undef, 'Simple undefined');

$str = 'true';
$res = $parser->true($str);
$res = $res->out;
is($res, !0, 'Simple true');

$str = 'false';
$res = $parser->false($str);
$res = $res->out;
is($res, !1, 'Simple false');

$str = '"foo"';
$res = $parser->string($str);
$res = $res->out;
is($res, 'foo', 'Simple string');

$str = 'foo';
$res = $parser->key($str);
$res = $res->out;
is($res, 'foo', 'Simple key');

$str = '"foo"';
$res = $parser->key($str);
$res = $res->out;
is($res, 'foo', 'Simple key');

$str = '"fo\"o"';
$res = $parser->key($str);
$res = $res->out;
is($res, 'fo"o', 'Escaped key');

$str = "'foo'";
$res = $parser->key($str);
$res = $res->out;
is($res, 'foo', 'Simple key');

$str = "'foo'";
$res = $parser->string($str);
$res = $res->out;
is($res, 'foo', 'Simple string');

$str = q!"f\"oo"!;
$res = $parser->string($str);
$res = $res->out;
is($res, 'f"oo', 'String with escaped double quote');

$str = q!"f\'oo"!;
$res = $parser->string($str);
$res = $res->out;
is($res, "f'oo", 'String with escaped single quote');

$str = q!"f\noo"!;
$res = $parser->string($str);
$res = $res->out;
is($res, "f\noo", 'String with escaped newline');

$str = q!"f\noo\0\b\f\r\v\\\\"!;
$res = $parser->string($str);
$res = $res->out;
is($res, qq/f\noo\0\b\f\r\x0B\\/, 'String with various escaped characters');

$str = q!"\xa9\u263A"!;
$res = $parser->string($str);
$res = $res->out;
is($res, "\x{a9}\x{263a}", 'String with \x and \u escapes');

$str = q!"\u263a\ud804\uDC10\u263a"!;
$res = $parser->string($str);
$res = $res->out;
is($res, "\x{263a}\x{11010}\x{263a}", 'String with astral-plane \u escapes');

$str = q!"\&"!;
$res = $parser->string($str);
$res = $res->out;
is($res, '&', 'String with unknown pass-through escape');

$str = '123';
$res = $parser->number($str);
$res = $res->out;
is($res, 123, 'simple number');

$str = '123.45';
$res = $parser->number($str);
$res = $res->out;
is($res, 123.45, 'float number');

$str = '123.45e2';
$res = $parser->number($str);
$res = $res->out;
is($res, 12345, 'number: int, frac, exp');

$str = '123e2';
$res = $parser->number($str);
$res = $res->out;
is($res, 12300, 'number: int, exp');

$str = '.123e2';
$res = $parser->number($str);
$res = $res->out;
is($res, 12.3, 'number: frac, exp');

$str = '5e3';
$res = $parser->number($str);
$res = $res->out;
is($res, 5000, 'number: int, exp');

$str = '0x1';
$res = $parser->number($str);
$res = $res->out;
is($res, 1, 'number: int, exp');

$str = '0Xdeadbeef';
$res = $parser->number($str);
$res = $res->out;
is($res, 0xDEADBEEF, 'number: int, exp');

$str = '[]';
$res = $parser->arrayref($str);
$res = $res->out;
is(ref $res, 'ARRAY', 'empty arrayref');
is(scalar @$res, 0);

$str = '[1,2,3]';
$res = $parser->arrayref($str);
$res = $res->out;
is(ref $res, 'ARRAY', 'simple arrayref');
is(scalar @$res, 3);
is($res->[ 0 ],  1);
is($res->[ 1 ],  2);
is($res->[ 2 ],  3);

$str = '[1,"foo",3]';
$res = $parser->arrayref($str);
$res = $res->out;
is($res->[ 0 ], 1);
is($res->[ 1 ], "foo");
is($res->[ 2 ], 3);

$str = "[1,'foo',3]";
$res = $parser->arrayref($str);
$res = $res->out;
is($res->[ 0 ], 1);
is($res->[ 1 ], "foo");
is($res->[ 2 ], 3);

$str = '[1,{foo:"bar",bar:6.66},3]';
$res = $parser->arrayref($str);
$res = $res->out;
is(ref $res, 'ARRAY', 'complex arrayref');
is($res->[ 0 ],     1);
is(ref $res->[ 1 ], 'HASH');
ok(exists $res->[ 1 ]{foo});
ok(exists $res->[ 1 ]{bar});
is($res->[ 1 ]{foo}, 'bar');
is($res->[ 1 ]{bar}, 6.66);
is($res->[ 2 ],      3);

$str = "[1,{foo:'bar',bar:6.66},3]";
$res = $parser->arrayref($str);
$res = $res->out;
is(ref $res, 'ARRAY', 'complex arrayref');
is($res->[ 0 ],     1);
is(ref $res->[ 1 ], 'HASH');
ok(exists $res->[ 1 ]{foo});
ok(exists $res->[ 1 ]{bar});
is($res->[ 1 ]{foo}, 'bar');
is($res->[ 1 ]{bar}, 6.66);
is($res->[ 2 ],      3);

$str = '{}';
$res = $parser->hashref($str);
$res = $res->out;
is(ref $res, 'HASH', 'empty hashref');
is(scalar keys %$res, 0);

$str = '{k:"v",y:undefined}';
$res = $parser->hashref($str);
$res = $res->out;
is(ref $res, 'HASH', 'simple hashref');
is((sort keys %$res)[ 0 ], 'k');
is((sort keys %$res)[ 1 ], 'y');
is($res->{k},              'v');
is($res->{y},              undef);

$str = '{k:[1,undefined,3],y:{k:"v",y:false}}';
$res = $parser->hashref($str);
$res = $res->out;
is(ref $res, 'HASH', 'complex hashref');
is((sort keys %$res)[ 0 ], 'k');
is((sort keys %$res)[ 1 ], 'y');
is(ref $res->{k},          'ARRAY');
is($res->{k}[ 0 ],         1);
is($res->{k}[ 1 ],         undef);
is($res->{k}[ 2 ],         3);
is(ref $res->{y},          'HASH');
ok(exists $res->{y}{k});
ok(exists $res->{y}{y});
is($res->{y}{k}, 'v');
is($res->{y}{y}, !(1==1));
