use Test::More qw<no_plan>;
use strict;
use warnings;
use JavaScript::HashRef::Decode qw<decode_js>;

# This uses the JavaScript::HashRef::Decode **EXTERNAL INTERFACE**

my $str;
my $res;

$str = '{}';
$res = decode_js($str);
is(ref $res, 'HASH', 'empty hashref');
is(scalar keys %$res, 0);

$str = '{k:"v",y:undefined}';
$res = decode_js($str);
is(ref $res, 'HASH', 'simple hashref');
is((sort keys %$res)[ 0 ], 'k');
is((sort keys %$res)[ 1 ], 'y');
is($res->{k},              'v');
is($res->{y},              undef);

$str = "{k:'v',y:undefined}";
$res = decode_js($str);
is(ref $res, 'HASH', 'simple hashref');
is((sort keys %$res)[ 0 ], 'k');
is((sort keys %$res)[ 1 ], 'y');
is($res->{k},              'v');
is($res->{y},              undef);

$str = '{k:[1,undefined,3],y:{k:"v",y:123}}';
$res = decode_js($str);
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

