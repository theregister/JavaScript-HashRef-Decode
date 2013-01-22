package JavaScript::HashRef::Decode;

## ABSTRACT: JavaScript "simple object" (hashref) decoder

use strict;
use warnings;
use Parse::RecDescent;
use Exporter qw<import>;
our @EXPORT_OK = qw<decode_js>;

our $js_grammar = <<'END_GRAMMAR';
number:     /[0-9]+(\.[0-9]+)?/
{
    $return = bless {
        value => $item[1],
    }, 'JavaScript::HashRef::Decode::NUMBER';
}
string_double_quoted:
    m{"             # Starts with a single-quote
      (               # Start capturing *inside* the double-quote
        (
            \\.           # An escaped-something
            |             # .. or
            [^"]          # Anything that's not a double-quote
        )*              # 0+ combination of the previous

      )               # End capturing *inside* the double-quote
    "               # Ends with a double-quote
    }x
{
    $return = bless {
        value => "$1",
    }, 'JavaScript::HashRef::Decode::STRING';
}
string_single_quoted:
    m{'             # Starts with a single-quote
      (               # Start capturing *inside* the single-quote
        (
            \\.           # An escaped-something
            |             # .. or
            [^']          # Anything that's not a single-quote
        )*              # 0+ combination of the previous

      )               # End capturing *inside* the single-quote
    '               # Ends with a single-quote
    }x
{
    $return = bless {
        value => "$1",
    }, 'JavaScript::HashRef::Decode::STRING';
}
unescaped_key:        m{[a-zA-Z_][a-zA-Z_0-9]*}
{
    $return = bless {
        key => $item[1],
    }, 'JavaScript::HashRef::Decode::KEY';
}
string: string_single_quoted | string_double_quoted
key:       unescaped_key | string
token_undefined:    "undefined"
{
    $return = bless {
    }, 'JavaScript::HashRef::Decode::UNDEFINED';
}
token_null:         "null"
{
    $return = bless {
    }, 'JavaScript::HashRef::Decode::UNDEFINED';
}
undefined: token_undefined | token_null
true:  "true"
{
    $return = bless {
    }, 'JavaScript::HashRef::Decode::TRUE';
}
false:  "false"
{
    $return = bless {
    }, 'JavaScript::HashRef::Decode::FALSE';
}
boolean: true | false
any_value:  number | string | hashref | arrayref | undefined | boolean
tuple:  key ":" any_value
{
    $return = bless {
        key => $item[1],
        value => $item[3],
    }, 'JavaScript::HashRef::Decode::TUPLE';
}
list_of_values: <leftop: any_value "," any_value>(s?)
arrayref:   "[" list_of_values "]"
{
    $return = bless $item[2], 'JavaScript::HashRef::Decode::ARRAYREF';
}
tuples:     <leftop: tuple "," tuple>(s?)
hashref:    "{" tuples "}"
{
    $return = bless $item[2], 'JavaScript::HashRef::Decode::HASHREF';
}
END_GRAMMAR

our $parser;

=head1 NAME

JavaScript::HashRef::Decode - a JavaScript "data hashref" decoder for Perl

=head1 DESCRIPTION

This module "decodes" a simple data-only JavaScript "object" and returns a
Perl hashref constructed from the data contained in it.

It only supports "data" which comprises of: hashrefs, arrayrefs, single- and
double-quoted strings, numbers, and "special" token the likes of "undefined",
"true", "false", "null".

It does not support functions, nor is it meant to be an all-encompassing parser
for a JavaScript object.

If you feel like the JavaScript structure you'd like to parse cannot
effectively be parsed by this module, feel free to look into the
L<Parse::RecDescent> grammar of this module.

Patches are always welcome.

=head1 SYNOPSIS

    use JavaScript::HashRef::Decode qw<decode_js>;
    use Data::Dumper::Concise;
    my $js   = q!{ foo: "bar", baz: { quux: 123 } }!;
    my $href = decode_js($js);
    print Dumper $href;
    {
        baz => {
            quux => 123
        },
        foo => "bar"
    }

=head1 EXPORTED SUBROUTINES

=head2 C<decode_js($str)>

Given a JavaScript object thing (i.e. an hashref), returns a Perl hashref
structure which corresponds to the given data

  decode_js('{foo:"bar"}');

Returns a Perl hashref:

  { foo => 'bar' }

The L<Parse::RecDescent> internal interface is reused across invocations.

=cut

sub decode_js {
    my ($str) = @_;

    $parser = Parse::RecDescent->new($js_grammar)
        if !defined $parser;
    my $parsed = $parser->hashref($str);
    die "decode_js: Cannot parse (invalid js?) \"$str\""
        if !defined $parsed;
    return $parsed->out;
}

# For each "type", provide an ->out function which returns the proper Perl type
# for the structure, possibly recursively

=head1 CAVEATS & BUGS

=over

=cut


package JavaScript::HashRef::Decode::NUMBER;

sub out {
    return $_[ 0 ]->{value};
}

package JavaScript::HashRef::Decode::STRING;

=item STRINGS

JavaScript string interpolation only works for the following escaped values:
C<\">, C<\'>, C<\n>, C<\t>.

=cut

sub out {
    my $val = $_[ 0 ]->{value};
    $val =~ s/\\"/"/g;
    $val =~ s/\\'/'/g;
    $val =~ s/\\n/\n/g;
    $val =~ s/\\t/\t/g;
    return $val;
}

package JavaScript::HashRef::Decode::UNDEFINED;

sub out {
    return undef;
}

package JavaScript::HashRef::Decode::TRUE;

sub out {
    return (1 == 1);
}

package JavaScript::HashRef::Decode::FALSE;

sub out {
    return (1 == 0);
}

package JavaScript::HashRef::Decode::ARRAYREF;

sub out {
    return [ map {$_->out} @{ $_[ 0 ] } ];
}

package JavaScript::HashRef::Decode::KEY;

sub out {
    return $_[ 0 ]->{key}
}

package JavaScript::HashRef::Decode::TUPLE;
sub out {
    return $_[ 0 ]->{key}->out => $_[ 0 ]->{value}->out
}

package JavaScript::HashRef::Decode::HASHREF;

sub out {
    return { map {$_->out} @{ $_[ 0 ] } };
}

=back

=head1 SEE ALSO

L<Parse::RecDescent>

The ECMAScript Object specification.

=head1 AUTHOR

Marco Fontani - L<MFONTANI@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2013 Situation Publishing LTD

=cut

1;
