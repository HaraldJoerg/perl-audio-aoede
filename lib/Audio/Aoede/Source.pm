# ABSTRACT: One source in the Aoede Orchestra
use 5.032;
package Audio::Aoede::Source 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Source {
    use PDL;
    use Audio::Aoede::Link;

    field $volume   :param :reader = 1;
    field $function :param :reader = undef;
    field $rate     :param :reader;
    field $effects  :param = [];
    field @effects = ();
    # These fields are used if a source is read in batches
    field $link     = Audio::Aoede::Link->new;
    field $shutdown = 0;
    field %trailer_amplitudes;
    field $trailer_done = 0;

    ADJUST {
        @effects = @$effects;
        undef $effects;
    }

    method set_volume ($new) {
        $volume = $new;
    }

    method shutdown () {
        $shutdown = 1;
    }

    method next_samples ($n_samples, $first = 0) {
        my $offset = $link->offset;

        if ($offset > $first) {
            $link->set_offset($first);
            $offset = $first;
        }
        my $samples;
        if ($shutdown) {
            $samples = $self->trailer_samples($n_samples,$first - $offset);
        }
        else {
            $samples = $volume * $function->($n_samples,$first - $offset);
            for my $effect (@effects) {
                $samples = $effect->apply($samples,$first-$offset);
            }
        }
        return $samples;
    }


    method trailer_samples ($n_samples,$first) {
        if (! $trailer_done) {
            %trailer_amplitudes = map {
                builtin::refaddr $_  =>  $volume * $_->release($first);
            } @effects;
        }
        my $next = $trailer_done + $n_samples;
        my @trailers = map {
            my $id = builtin::refaddr $_;
            my $amplitude = $trailer_amplitudes{$id};
            my @trailer = (); # default is zero elements
            if (defined $amplitude) {
                if ($next >= $amplitude->dim(0)) {
                    @trailer = ($amplitude->slice([$trailer_done,-1])
                                * $function->($amplitude->dim(0)-$trailer_done,
                                              $first));
                    delete $trailer_amplitudes{$id}; # this effect is done
                }
                else {
                    @trailer = ($amplitude->slice([$trailer_done,$next-1])
                                * $function->($n_samples,$first));
                }
            }
            @trailer;
        } @effects;
        if (@trailers) {
            $trailer_done += $n_samples;
            return pdl(zeroes($n_samples),@trailers)->transpose->sumover;
        }
        else {
            $shutdown = 0;
            $trailer_done = 0;
            return;
        }
    }


    method trailer ($first) {
        my @amplitudes = map { $volume * $_->release($first) } @effects;
        my @trailers = map {
            isempty $_
                ? empty
                : $_ * $function->($_->dim(0),$first);
            } @amplitudes;
        return pdl(@trailers)->transpose->sumover;
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

=item 2. C<next_samples($n_samples,$first)>

Return C<$n_samples> samples starting at C<$first>.  The samples are
float (or double) L<PDL> objects.

=back

=head1 METHODS

=head2 C<< $trailer = $source->trailer($first) >>

Returns a one-dimensional ndarray containing the complete trailer
(samples created by effects after the duration of the original
samples) starting at the C<$first> sample.

This is used to collect the trailer after notes with a fixed duration
in C<mrt_play>.

=cut
