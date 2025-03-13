# ABSTRACT: One voice in the Aoede Orchestra
use 5.032;
package Audio::Aoede::Voice 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Voice {
    use PDL;

    use Audio::Aoede::Tone;

    field $samples = pdl([]);
    field $carry   = pdl([]);
    field $rate   :param;
    field $tuning :param = undef;

    my %dynamics = (
        fff => 1.0,
        ff  => 0.8,
        f   => 0.6,
        mf  => 0.5,
        mp  => 0.4,
        p   => 0.3,
        pp  => 0.2,
        ppp => 0.1
    );

    ADJUST {
        if (! defined $tuning) {
            require Audio::Aoede::Tuning::Equal;
            $tuning = Audio::Aoede::Tuning::Equal->new;
        }
    }

    method add_notes($track,$bpm = 120,$dynamic = 'mf') {
        my $timbre = $track->timbre;
        for my $note ($track->notes) {
            my @pitches = $tuning->note2pitch($note);
            my $tone = Audio::Aoede::Tone->new(
                intensity => $dynamics{$dynamic} // 0.5,
                duration => $note->duration,
                timbre => $timbre,
                pitches => \@pitches,
                );
            my ($tone_samples,$tone_carry) = $tone->sequence($rate,$bpm);
            my $n_samples =  $tone_samples->dim(0);
            if ($carry->dim(0) > $n_samples) {
                $tone_samples += $carry->slice([0,$n_samples-1]);
                $carry = pdl($carry->slice([$n_samples,$carry->dim(0)-1]),
                             $tone_carry)->transpose->sumover;
            }
            else {
                $tone_samples = pdl($tone_samples,$carry)->transpose->sumover;
                $carry = $tone_carry;
            }
            $samples = $samples->append($tone_samples);
        }
    }


    # FIXME: This should drain $carry.  For the current use (adding a
    # voice in a later section) this is not relevant.
    method add_samples($new) {
        $samples = $samples->append($new);
    }


    method n_samples () {
        return $samples->dim(0);
    }


    method samples () {
        my $norm = $samples->abs->max;
        return $norm ? $samples/$norm : $samples;
    }


    method drain_carry ($n_samples) {
        my $drain;
        my $n_carry = $carry->dim(0);
        if ($n_carry > $n_samples) {
            $drain = $carry->slice([0,$n_samples-1]);
            $carry = $carry->slice([$n_samples,$n_carry-1]);
        }
        else {
            $drain = zeroes($n_samples);
            $drain->slice([0,$n_carry-1]) = $carry;
            $carry = pdl([]);
        }
        $samples = $samples->append($drain);
    }


    method carry () {
        my $norm = $samples->abs->max;
        return $norm ? $carry/$norm : $carry;
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

=item C<add_notes($notes_ref,$bpm)>

Add a L<Audio::Aoede::Track> object with notes.  The method should be
renamed to add_track.  C<$bpm> the current speed in (beats per
minute).

=item C<samples>

Return the samples accumulated so far, as a 1D L<PDL> object.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
