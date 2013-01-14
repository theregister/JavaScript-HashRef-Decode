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
key:        m{[a-zA-Z_][a-zA-Z_0-9]*}
{
    $return = bless {
        key => $item[1],
    }, 'JavaScript::HashRef::Decode::KEY';
}
undefined: "undefined"
{
    $return = bless {
    }, 'JavaScript::HashRef::Decode::UNDEFINED';
}
string: string_single_quoted | string_double_quoted
any_value:  number | string | hashref | arrayref | undefined
key_value:  key ":" any_value
{
    $return = bless {
        key => $item[1],
        value => $item[3],
    }, 'JavaScript::HashRef::Decode::KEY_VALUE';
}
list_of_values: <leftop: any_value "," any_value>(s?)
arrayref:   "[" list_of_values "]"
{
    $return = bless $item[2], 'JavaScript::HashRef::Decode::ARRAYREF';
}
key_values: <leftop: key_value /,/ key_value>(s?)
hashref:    "{" key_values "}"
{
    $return = bless $item[2], 'JavaScript::HashRef::Decode::HASHREF';
}
END_GRAMMAR

our $parser;

=head2 SYNOPSIS

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

    $parser //= Parse::RecDescent->new($js_grammar);
    my $parsed = $parser->hashref($str);
    return $parsed->out;
}

# For each "type", provide an ->out function which returns the proper Perl type
# for the structure, possibly recursively

=head2 CAVEATS & BUGS

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

package JavaScript::HashRef::Decode::ARRAYREF;

sub out {
    return [ map {$_->out} @{ $_[ 0 ] } ];
}

package JavaScript::HashRef::Decode::KEY;

=item KEYS

JavaScript keys cannot be strings or numbers, but an "identifier" which starts
with a letter or underscore, and contains letters, underscores or numbers
afterwards.

=cut

sub out {
    return $_[ 0 ]->{key}
}

package JavaScript::HashRef::Decode::KEY_VALUE;
sub out {
    return $_[ 0 ]->{key}->out => $_[ 0 ]->{value}->out
}

package JavaScript::HashRef::Decode::HASHREF;

sub out {
    return { map {$_->out} @{ $_[ 0 ] } };
}

1;
