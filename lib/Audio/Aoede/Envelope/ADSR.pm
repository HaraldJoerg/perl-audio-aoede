# ABSTRACT: An envelope for Aoede voices
package Audio::Aoede::Envelope::ADSR;
use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Envelope::ADSR {
    use PDL;

    field $attack  :param;
    field $decay   :param;
    field $sustain :param;
    field $release :param;

    # FIXME: We can get a concave decay with a formula like this:
    # $s = zeroes(10)->xlinvals((1-$sustain)**0.5,0)->pow(2)+$sustained
    ADJUST {
        # Convert numbers of samples to 1D PDL arrays
        $attack  = $attack
            ? (sequence($attack) + 1) / $attack
            : undef;
        $decay   = $decay
            ? zeroes($decay)->xlinvals(1,$sustain)
            : undef;
        # $release needs to be adjusted to the actual value
        # during apply()
        $release = $release
            ? zeroes($release)->xlinvals(1,0)
            : undef;
    }

    method apply ($samples) {
        my $n_samples = $samples->dim(0);
        my $start = 0;
        if (defined $attack) {
            my $a_samples = $attack->dim(0);
            my $rest_samples = $n_samples - $a_samples;
            if ($rest_samples < 0) {
                $samples  *= $attack->slice([0,$n_samples-1]);
            }
            else {
                $samples->slice([0,$a_samples-1]) *= $attack;
            }
            $n_samples  = $rest_samples;
            $start      = $a_samples;
        }
        if (defined $decay  &&  $n_samples > 0) {
            my $d_samples = $decay->dim(0);
            my $rest_samples = $n_samples - $d_samples;
            if ($rest_samples < 0) {
                $samples->slice([$start,$start + $n_samples-1])
                    *= $decay->slice([0,$n_samples-1]);
            }
            else {
                $samples->slice([$start,$start + $d_samples-1])
                    *= $decay;
            }
            $n_samples = $rest_samples;
            $start += $d_samples;
        }
        if ($n_samples > 0) {
            $samples->slice([$start,$start + $n_samples-1]) *= $sustain;
        }
        my $last  =  $samples->at(-1);
        my $carry =  defined $release ? $release * $last : undef;
        return ($samples,$carry);
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Envelope::ADSR - a "classic" volume envelope

=head1 SYNOPSIS

  use Audio::Aoede::Envelope::ADSR;
  $envelope = Audio::Aoede::Envelope::ADSR->new(
      attack  => $attack_samples,
      decay   => $decay_samples,
      sustain => $sustain_level,
      release => $release_samples,
  );
  my ($modified,$carry) = $envelope->apply($samples);

=head1 DESCRIPTION

Quoted from Wikipedia: "In sound and music, an envelope describes how
a sound changes over time".  A plucked guitar string creates an
initial sound almost immediately, and then continually fades away
until zero, or until mechanically damped by the player.

This class uses the number of samples as a unit of time to avoid
off-by-one errors when adding floating point values.

The most common envelope generators, called ADSR generators for fairly
obvious reasins, are controlled with four parameters:

=over

=item Attack

The number of samples between the sound starts and reaches its full
peak.  The attack time is low for a piano or guitar, but may be
audible for a wind organ or a glass harp.

=item Decay

The number of samples between the sound at its peak and its sustain
level.

=item Sustain

This is the only parameter which is not a number of samples but a
fraction.  It is the sound level sustained for an arbitrary long time
after the decay phase.  A guitar has a sustain value of zero, while
the sustain value of wind instruments is close to one.

=item Release

The number of samples between the end of a note being played and its
sound reaching zero.

=back

=head2 METHODS

=over

=item C<< $env = Audio::Aoede::Envelope->new(%params) >>

Creates a new envelope object.  The constructor parameters are
C<attack>, C<decay>, C<sustain> and C<release>, their purpose is
explained in the L<description|/#DESCRIPTION>.  C<attack>, C<decay>
and C<release>, are given in sample numbers, C<sustain> does not carry
a unit.

=item C<< ($mod_samples,$carry) = $env->apply($samples) >>

Apply the envelope to C<$samples>.  Returns an array of two 1D PDL
arrays: The first array has the same dimension as the input array,
and the second has the dimension C<$release_samples>.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
