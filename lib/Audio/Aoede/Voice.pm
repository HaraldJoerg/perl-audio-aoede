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
  $voice = Audio::Aoede::Voice->new(rate => 44100);

=head1 DESCRIPTION

This module collects L<Audio::Aoede::Track> objects of
L<Audio::Aoede::Note>s and applies a tuning to convert them to a
one-dimensional PDL array of samples.  The number of samples
corresponds to the length of the track and the sample rate.

Effects (like reverb) which cause notes to be audible after the
nominal duration of the track are collected in another one-dimensional
PDL array, the length of which may vary depending on the effects.

=head1 METHODS

=head2 $voice = Audio::Aoede::Voice->new(%params)

Creates an Audio::Aoede::Voice object from a hash of parameters.  The
keys of the hash are:

=over

=item C<rate>

The number of samples per second to be created.

=item C<tuning>

The rule to convert a L<Audio::Aoede::Note> object into a
pitch value, given as an object which provides a method
C<note2pitch>.

=back

=head2 $samples = $voice->samples()

Return the samples accumulated so far, as a 1D L<PDL> object,
scaled to the interval [-1,1]

=head2 $carry = $voice->carry()

Return the samples corresponding to sound after the nominal duration
of the track as a L<PDL> object, scaled with the same scale as the
samples.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
