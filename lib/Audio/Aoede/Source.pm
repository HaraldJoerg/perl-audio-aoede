# ABSTRACT: One source in the Aoede Orchestra
use 5.032;
package Audio::Aoede::Source 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Source {
    use PDL;
    use Audio::Aoede::Link;

    field $volume   :param = 1;
    field $function :param;
    field $link     = Audio::Aoede::Link->new;


    method volume {
        return $volume;
    }


    method next_samples ($n_samples, $since) {
        return $function->($n_samples,$since - $link->offset);
    }


    method set_link($new_link) {
        $link = $new_link;
        return $self;
    }
}

1;

=head1 NAME

Audio::Aoede::Source - A source of samples

=head1 SYNOPSIS

...to be written.

=head1 DESCRIPTION

FIXME: A source might at some time be a role.
A source must provide two methods:

=over

=item 1. C<volume>

Return the volume of the source.  This value is used to mix sources.
The default value is 1.0.

=item 2. C<next_samples($n_samples,$since)>

Return C<$n_samples> samples starting at C<$since>.  The samples are
float (or double) L<PDL> objects.

=back

=cut

