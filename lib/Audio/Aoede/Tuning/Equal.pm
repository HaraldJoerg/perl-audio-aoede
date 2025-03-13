# Abstract: Equal musical tuning
package Audio::Aoede::Tuning::Equal;

use Feature::Compat::Class;
use feature 'signatures';
use feature 'isa';
no warnings 'experimental';

class Audio::Aoede::Tuning::Equal;

use constant A440     => 440;
use constant HALFTONE => 2**(1/12);

field $base :param = A440;


my %diatonic_intervals = (
    C => 0,   D => 2,   E => 4,   F => 5,   G => 7,   A => 9,   B => 11,
);


method note2pitch ($note) {
    return map { $base * (HALFTONE ** ($_-69)) } ($note->midi_number);
}

1;
