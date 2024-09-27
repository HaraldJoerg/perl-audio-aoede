# ABSTRACT: One voice in the Aoede Orchestra
use 5.032;
package Audio::Aoede::Voice 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Voice {
    use PDL;

    use Audio::Aoede::Note;
    use Audio::Aoede::Units qw( seconds_per_note );
    use Audio::Aoede::Envelope;

    field $function          :param;
    field $envelope_function :param = sub { Audio::Aoede::Envelope->new() };
    field $samples = pdl([]);
    field $carry;

    # Currently defunct, I might want to enable it (again) later.
    #
    # method add_named_notes($notes_string) {
    #     my @note_strings = split " ",$notes_string; # " " strips leading spaces
    #     for my $note_string(@note_strings) {
    #         my $note = Audio::Aoede::Note->parse_note($note_string);
    #         my $n_samples = $note->duration() * rate() * seconds_per_note;
    #         my @pitches = $note->pitches;
    #         my $new_samples = @pitches ?
    #             sumover pdl(map {
    #                 $function->($n_samples,$_)
    #             } $note->pitches)->transpose
    #         :
    #             zeroes($n_samples);
    #         $samples = $samples->append($new_samples);
    #     }
    # }

    method add_notes($track,$rate,$bpm) {
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
            my @pitches = $note->pitches;
            my @carry;
            if (@pitches) {
                for my $pitch (@pitches) {
                    my $add_samples = $function->($n_samples,$pitch);
                    my $add_carry;
                    my $envelope    = $envelope_function->($pitch);
                    ($add_samples,$add_carry) = $envelope->apply($add_samples);
                    $new_samples += $add_samples;
                    defined $add_carry  and  push @carry,$add_carry;
                }
            }
            $samples = $samples->append($new_samples);
            @carry  and  $carry = sumover pdl(@carry)->transpose;
        }
        defined $carry  and  $samples = $samples->append($carry);
    }

    method add_samples($new) {
        $samples = $samples->append($new);
    }

    method samples() {
        return $samples;
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
provude "next" samples and keep track of that value by itself, but
this fais if there's more than one consumer for the voice (for
example, a sound backend and an oscilloscope).

Work in progress!

=back

=item C<add_notes(@notes)>

Add a list of L<Audio::Aoede::Note> objects to the voice.

=item C<samples>

Return the samples accumulated so far, as a 1D L<PDL> object.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.


