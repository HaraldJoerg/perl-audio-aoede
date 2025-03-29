# Abstract: Equal musical tuning for Aoede
package Audio::Aoede::Tuning::Equal;

use Feature::Compat::Class;
use feature 'signatures';
use feature 'isa';
no warnings 'experimental';

class Audio::Aoede::Tuning::Equal;

use Audio::Aoede::Units qw( A440 HALFTONE );

field $base :param = A440;

method note2pitch ($note) {
    return map { $base * (HALFTONE ** ($_-69)) } ($note->midi_number);
}

1;

=head1 NAME

Audio::Aoede::Tuning::Equal - Equal musical tuning for Aoede

=head1 SYNOPSIS

  use Audio::Aoede::Tuning::Equal;
  my $converter = Audio::Aoede::Tuning::Equal->new;

  my $note = Audio::Aoede::Note->from_spn('C#4');
  my $pitch = $converter->note2pitch($note);

=head1 DESCRIPTION

This is the Aoede default tuning: Equal tuning.  An octave is split
logarithmically into 12 equal intervals, so that halftones are a
frequency factor of 2**(1/12) away from each other.

=head1 METHODS

=head2 $t = Audio::Aoede::Tuning::Equal->new(base => $base);

The constructor for this tuning has one parameter: The base frequency
is the frequency for the pitch A4 in Hz.  The default is 440.

=head2 $pitch = $t->note2pitch($note)

The method C<note2pitch> is a required method for tunings.  It takes
an Audio::Aoede::Note object as an argument and returns the pitch
corresponding to that note.

=cut
