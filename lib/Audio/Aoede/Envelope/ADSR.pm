# ABSTRACT: An envelope for Aoede voices
package Audio::Aoede::Envelope::ADSR;
use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Envelope::ADSR {
    use PDL;
    use Audio::Aoede;

    field $attack  :param = 0;
    field $decay   :param = 0;
    field $sustain :param = 1;
    field $release :param = 0;
    field $attack_samples;
    field $decay_samples;
    field $release_samples;

    # FIXME: We can get a concave decay with a formula like this:
    # $s = zeroes(10)->xlinvals((1-$sustain)**0.5,0)->pow(2)+$sustain
    ADJUST {
        my $rate = Audio::Aoede->instance->rate;
        # Convert numbers of samples to 1D PDL arrays
        if ($attack) {
            $attack = int ($attack * $rate);
            $attack_samples  = (sequence($attack) + 1) / $attack;
        } else {
            $attack_samples = undef;
        }

        if ($decay) {
            $decay = int ($decay * $rate);
            $decay_samples = zeroes($decay)->xlinvals(($decay-1)/
                                                      $decay,$sustain);
        } else {
            $decay_samples = undef;
        }

        # $release needs to be adjusted to the actual amplitude
        # at the time of releasing
        if ($release) {
            $release = int ($release * $rate);
            $release_samples = zeroes($release)->xlinvals(($release-1)/
                                                          $release,0);
        }
        else {
            $release_samples = undef;
        }
    }

    method apply ($samples,$offset) {
        # Envelope: |<- A ->|<- D ->|<- S ... ->|<- R ->|
        # Params:   |<- O ->|<- Samples ->|<- continue?
        #
        # $samples are the input samples.
        # $offset is the first sample of the envelope which needs to be
        #         evaluated.  It can point into the A, D and S regions.
        # $release is a boolean, a true value is indicating that the end
        #         of this batch of samples starts the release phase.
        # $first  is the first sample  of the incoming samples which still
        #         needs processing.  So, samples 0 to ($first-1) are already
        #         done, and $first is updated after each phase.
        # $last   is the last sample of this batch.
        my $first = 0;
        my $last  = $samples->dim(0)-1;
        my $continue = 1;
        if ($attack) {
            if ($offset > $attack) {
                # |<- attack ->|<- decay ->|<- sustain ... ->|<- release ->|
                # Attack phase is already over, remaining offset goes to decay
                $offset -= $attack;
            }
            else {
                # |<- attack ->|<- decay ->|<- sustain ... ->|<- release ->|
                # |<- O ->|<-   samples ...
                if ($attack > $offset + $last) {
                    # |<-         A         ->|<- D ->|<- S ... ->|<- R ->|
                    # |<- O ->|<- samples ->|
                    # This batch ends within the attack phase
                    $samples *= $attack_samples->slice([$offset,$offset+$last]);
                    $continue = 0;
                }
                else {
                    # |<-     A      ->|<- D ->|<- S ... ->|<- R ->|
                    # |<- O ->|<- samples ->|
                    # Complete attack and prepare decay phase
                    $samples->slice([$first,$attack-$offset-1]) *=
                        $attack_samples->slice([$offset,$attack-1]);
                    $first += ($attack - $offset);
                    $offset = 0;
                }
            }
        }
        if ($continue && $decay) {
            if ($offset > $decay) {
                # |<- decay ->|<- sustain ... ->|<- release ->|
                # |<-     offset   ->|<-   samples ...
                $offset -= $decay;
            }
            else {
                # |<- decay ->|<- sustain ... ->|<- release ->|
                # |<- O ->|<-   samples ...
                if ($first + $decay > $offset + $last) {
                    # |<-   D                  ->|<- S ... ->|<- R ->|
                    # |<- O ->|<- samples ->| or
                    # ....   samples      ->|
                    # This batch ends within the decay phase
                    $samples->slice([$first,$last]) *=
                        $decay_samples->slice([$offset,$offset+$last-$first]);
                    $continue = 0;
                }
                else {
                    # |<-     D      ->|<- S ... ->|<- R ->|
                    # |<- O ->|<- samples ->| or
                    # ....   samples      ->|
                    # Complete decay and prepare sustain phase
                    $samples->slice([$first,$first-$offset+$decay-1]) *=
                        $decay_samples->slice([$offset,$decay-1]);
                    $first += ($decay - $offset);
                    $offset = 0;
                }
            }
        }
        if ($continue) {
            $samples->slice([$first,$last]) *= $sustain;
        }

        return $samples;
    }


    method release ($first) {
        return pdl([]) unless $release;
        my $amplitude;
        if ($attack  and  $first < $attack) {
            $amplitude = $first / $attack;
        }
        elsif ($decay  and  $first + $attack < $decay) {
            $amplitude  = 1.0
                + ((-1.0 + $sustain) / $decay) * ($first - $attack);
        }
        else {
            $amplitude = $sustain;
        }
        return $amplitude * $release_samples;
    }


    method info {
        return { A => $attack,
                 D => $decay,
                 S => $sustain,
                 R => $release };
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
