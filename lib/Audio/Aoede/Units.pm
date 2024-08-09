# ABSTRACT: Units and conversion functions
package Audio::Aoede::Units;

use feature 'signatures';
no warnings 'experimental';

use Exporter 'import';
our @EXPORT_OK = qw(
                       HALFTONE
                       CENT
                       PI
                       duration2samples
                       named_note2frequency
                       rate
               );

use Carp;
use MIDI;

use constant PI       => atan2(0,-1); # Math::Trig collides with PDL
use constant A440     => 440;
use constant HALFTONE => 2**(1/12);
use constant CENT     => 2**(1/1200);

# Calculate the frequency of a note given by name, in equal-tempered
# tuning
sub named_note2frequency ($note) {
    my $midi_number = $MIDI::note2number{$note}
        or croak "note2frequency:  Unknown note name '$note'\n";
    # The names in %MIDI::note2number are one octave off, their A4 is
    # number 57
    return 2 * A440 * (HALFTONE**($midi_number-57));
}

# The rate (number of samples per second) should only be set once, or
# left at its default value.
my $rate = 44100;

sub rate { return $rate };

# The tempo is a MIDI term giving the number of microseconds per
# quarter note.  This can be changed.
my $tempo = 500_000;

sub set_tempo ($new_tempo) {
    $tempo = $new_tempo;
}


# Convert a duration in units of "full notes" to the number of samples
# for the current tempo and rate
sub duration2samples ($duration) {
    return $duration * $rate * $tempo / 250_000;
}
