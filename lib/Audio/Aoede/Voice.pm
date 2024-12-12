# ABSTRACT: One voice in the Aoede Orchestra
use 5.032;
package Audio::Aoede::Voice 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Voice :isa(Audio::Aoede::Source) {
    use PDL;

    use Audio::Aoede::Notes;
    use Audio::Aoede::Units qw( seconds_per_note );
    use Audio::Aoede::Envelope;

    field $envelope_function :param = sub { Audio::Aoede::Envelope->new() };
    field $samples = pdl([]);
    field $carry;


    method add_notes($track,$rate,$bpm = 120) {
        for my $note (@$track) {
            my $n_samples =  $note->duration * seconds_per_note($bpm) * $rate;
            my $new_samples;
            if (defined $carry) {
                if ($carry->dim(0) > $n_samples) {
                    $new_samples = $carry->slice([0,$n_samples-1]);
                    $carry = $carry->slice([$n_samples,$carry->dim(0)-1]);
                }
                else {
                    $new_samples = sumover pdl(zeroes($n_samples),
                                               $carry)->transpose;
                    undef $carry;
                }
            }
            else {
                $new_samples = zeroes($n_samples);
            }
            my @carry = defined $carry ? ($carry) : ();
            my @pitches = $note->pitches;
            use constant PI => atan2(0,-1);
            if (@pitches) {
                for my $pitch (@pitches) {
                    my $frequency = $pitch;
                    my $rate = 44100; # FIXME FIXME FIXME
                    my $samples_per_period = $rate / $frequency;
                    my $note = Audio::Aoede::Source->new(
                        function => sub ($n_samples,$first=0) {
                            # FIXME: Where does the note get its
                            # pitched function from?  It used to be an
                            # attribute... but AA::Source takes
                            # non-pitched functions!  I *want* it to
                            # be an attribute of the track, which is
                            # not yet an object.  Right now we *cheat*
                            # and fallback to a sine function until we
                            # are sure that we like the mechanism.
                            my $samples_per_period = $rate / $frequency;
                            my $norm = 2 * PI() / $samples_per_period;
                            $first -= $samples_per_period * int $first/$samples_per_period;
                            my $phase = (sequence($n_samples) + $first) * $norm;
                            my $samples = sin($phase);
                            return $samples;
                        },
                        effects => [
                            Audio::Aoede::Envelope::ADSR->new(
                                attack  => int(2 * $samples_per_period),
                                decay   => int(400 * $samples_per_period),
                                sustain => 0.1,
                                release => int(50 * $samples_per_period)
                            ),
                        ]
                    );
                    my $add_samples = $note->next_samples($n_samples);
                    $new_samples += $add_samples;
                    # my $add_samples = $self->function->($n_samples,$pitch);
                    # my $add_carry;
                    # my $envelope    = $envelope_function->($pitch);
                    # ($add_samples,$add_carry) = $envelope->apply($add_samples,0);
                    # $new_samples += $add_samples;
                    # if (defined $add_carry) {
                    #     my $n_carry = $add_carry->dim(0);
                    #     push @carry,
                    #         $self->function->($n_carry,$pitch,$n_samples) * $add_carry;
                    # }
                }
            }
            $samples = $samples->append($new_samples);
            @carry  and  $carry = sumover pdl(@carry)->transpose;
        }
    }


    method add_samples($new) {
        $samples = $samples->append($new);
    }


    method n_samples () {
        return $samples->dim(0);
    }


    method samples () {
        return $samples;
    }


    method drain_carry ($n_samples) {
        my $drain;
        if (defined $carry) {
            my $n_carry = $carry->dim(0);
            if ($n_carry > $n_samples) {
                $drain = $carry->slice([0,$n_samples-1]);
                $carry = $carry->slice([$n_samples,$n_carry-1]);
            }
            else {
                $drain = zeroes($n_samples);
                $drain->slice([0,$n_carry-1]) = $carry;
                undef $carry;
            }
        }
        else {
            $drain = zeroes($n_samples);
        }
        $samples = $samples->append($drain);
    }


    method carry () {
        return $carry;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Voice - One voice in the Aoede Orchestra

=head1 SYNOPSIS

  use Audio::Aoede::Voice;
  $voice = Audio::Aoede::Voice->new(function => sub {...})

=head1 DESCRIPTION

This module is about to be changed heavily while the Aoede synthesizer
is being worked on.

=head1 METHODS

=over

=item C<< $voice = Audio::Aoede::Voice->new(function => \&func) >>

Create a new voice object.  Currently there is only one construction
paraneter:

=over

=item C<function>

This is a reference to a subroutine which returns the next batch of
samples.  It takes three parameters: The number of samples, the
frequency, and the initial sample number (optional, defaults to 0).

Probably the frequency will at some point be optional, too, since
there are noises which can not be described by one frequency.

The initial sample number is not used yet.  It is intended to support
voices with low-frequency oscillators.  The voice might be able to
provide "next" samples and keep track of that value by itself, but
this fails if there's more than one consumer for the voice (for
example, a sound backend and an oscilloscope).

Work in progress!

=back

=item C<add_notes($notes_ref,$rate,$bpm)>

Add an array of L<Audio::Aoede::Notes> objects, given as a reference,
to the voice.  C<$rate> is the sample rate. C<$bpm> the current speed
in (beats per minute).

=item C<samples>

Return the samples accumulated so far, as a 1D L<PDL> object.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
