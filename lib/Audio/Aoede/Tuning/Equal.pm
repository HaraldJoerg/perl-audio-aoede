# Abstract: Equal musical tuning
package Audio::Aoede::Tuning::Equal;

use feature 'signatures';
no warnings 'experimental';

use Exporter qw( import );
our @EXPORT_OK = qw( note2pitch );

use constant A440     => 440;
use constant HALFTONE => 2**(1/12);



my %diatonic_intervals = (
    C => 0,   D => 2,   E => 4,   F => 5,   G => 7,   A => 9,   B => 11,
);

my $base = A440;

sub midi_number ($note) {
    my $octave = $note->octave;
    $octave  or  croak("Error: MIDI numbers need an octave");
    return $diatonic_intervals{uc $note->name}
        + $note->accidental
        + ($octave+1) * 12;
}

sub note2pitch ($note) {
    return $base * (HALFTONE ** (midi_number($note)-69));
}

1;
