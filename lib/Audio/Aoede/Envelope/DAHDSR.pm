# ABSTRACT: An SoundFont-type envelope for Aoede voices
package Audio::Aoede::Envelope::DAHDSR;

use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Envelope::DAHDSR;

use PDL;

use Audio::Aoede::Units qw( seconds_per_timecent cB_to_amplitude_factor);

field $rate    :param :reader;
field $delay   :param = 0;
field $attack  :param = 0;
field $hold    :param = 0;
field $decay   :param :reader = 0;
field $sustain :param :reader = 1;
field $release :param = 0;
field $env_samples :reader;
field $rel_samples;


sub new_from_sf ($class, %sf_params) {
    my %params = (rate => $sf_params{rate});
    for my ($key,$value) (%sf_params) {
        if ($key =~ /sustainModEnv/) {
            $params{sustain} = 1-$value/1000;
        }
        elsif ($key =~ /sustainVolEnv/) {
            $params{sustain} = 1/cB_to_amplitude_factor($value);
        }
        elsif (my ($name) = $key =~ /(^\w+)(Mod|Vol)Env/) {
            $params{lc $name} = $value <= -12000
                ? 0
                : seconds_per_timecent($value);
        }
        else {
            $params{$key} = $value;
        }
    }
    return $class->new(%params);
}


ADJUST {
    $env_samples = empty;
    if ($delay) {
        my $n_samples = int($delay * $rate + 0.5);
        $env_samples = $env_samples->append(zeroes($n_samples));
    }
    if ($attack) {
        my $n_samples = int($attack * $rate + 0.5);
        $env_samples = $env_samples->append(sequence($n_samples+1)/$n_samples);
    }
    if ($hold) {
        my $n_samples = int($hold * $rate + 0.5);
        $env_samples = $env_samples->append(ones($n_samples));
    }
    # Decay is done by SoundFont subclasses: The volume envelope uses
    # different units and rules than the modulation envelope.
}


method append_env_samples ($samples) {
    $env_samples = $env_samples->append($samples);
}

1;

__END__

=head1 NAME

Audio::Aoede::Envelope::DAHDSR - An Envelope for SoundFont

=head1 SYNOPSIS

TPD

=head1 DESCRIPTION

The SoundFont synthesis model uses envelopes ("envelope generators" in
their terminology) for volume contours and also for modulation.

These envelopes have six phases, their first letters make up the name
of this class:

=over

=item B<D>elay:

During this initial phase the value of the envelope is zero.
L<Audio::Aoede::Envelope::ADSR> envelopes have no such phase.

=item B<A>ttack:

The envelope rises "in a convex curve" from zero to one in the attack
phase.

=item B<H>old

During the hold phase the envelope value remains at 1.0.
L<Audio::Aoede::Envelope::ADSR> envelopes have no such phase.

=item B<D>ecay

During the decay phase the envelope decreases I<linearly> to the
sustain level.

=item B<S>ustain

This phase is defined by its envelope value and not by a time.

=item B<R>elease

This phase begins at the key-off event.  The envelope value decreases linearly from whatever the current value was to zero.

=back

=cut

