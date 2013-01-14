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

$str = '"foo"';
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

$str = '123';
$res = $parser->number($str);
$res = $res->out;
is($res, 123, 'simple number');

$str = '123.45';
$res = $parser->number($str);
$res = $res->out;
is($res, 123.45, 'float number');

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

$str = '{k:[1,undefined,3],y:{k:"v",y:123}}';
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
is($res->{y}{y}, 123);
