# ABSTRACT: Units and conversion functions
package Audio::Aoede::Units;
use 5.032;
use warnings;
use utf8; # for the note names

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

use constant PI       => atan2(0,-1); # Math::Trig collides with PDL
use constant A440     => 440;
use constant HALFTONE => 2**(1/12);
use constant CENT     => 2**(1/1200);

my %diatonic_notes = (
    C => 0,   D => 2,   E => 4,   F => 5,   G => 7,   A => 9,   B => 11,
);
my %diatonic_modifiers = (
    ''  =>  0,
    'b' => -1,   '♭' => -1,
    '#' =>  1,   '♯' =>  1,
);
my %note_symbols = (
    '𝅝' => 1,             # U+1D15D MUSICAL SYMBOL WHOLE NOTE
    '𝅗𝅥' => 1/2,           # U+1D15E MUSICAL SYMBOL HALF NOTE
    '𝅘𝅥' => 1/4,           # U+1D15F MUSICAL SYMBOL QUARTER NOTE
    '𝅘𝅥𝅮' => 1/8,           # U+1D160 MUSICAL SYMBOL EIGHTH NOTE
    '𝅘𝅥𝅯' => 1/16,          # U+1D161 MUSICAL SYMBOL SIXTEENTH NOTE
    '𝅘𝅥𝅰' => 1/32,          # U+1D162 MUSICAL SYMBOL THIRTY-SECOND NOTE
    '𝅘𝅥𝅱' => 1/64,          # U+1D163 MUSICAL SYMBOL SIXTY-FOURTH NOTE
    '𝅘𝅥𝅲' => 1/128,         # U+1D164 M. S. ONE HUNDRED TWENTY-EIGHTH NOTE
);
my $note_dot = '𝅭';        # U+1D16D MUSICAL SYMBOL COMBINING AUGMENTATION DOT
my %rest_symbols = (
    '𝄻' => 1,             # U+1D13B MUSICAL SYMBOL WHOLE REST
    '𝄼' => 1/2,            # U+1D13C MUSICAL SYMBOL HALF REST
    '𝄽' => 1/4,            # U+1D13D MUSICAL SYMBOL QUARTER REST
    '𝄾' => 1/8,            # U+1D13E MUSICAL SYMBOL EIGHTH REST
    '𝄿' => 1/16,           # U+1D13F MUSICAL SYMBOL SIXTEENTH REST
    '𝅀' => 1/32,           # U+1D140 MUSICAL SYMBOL THIRTY-SECOND REST
    '𝅁' => 1/64,           # U+1D141 MUSICAL SYMBOL SIXTY-FOURTH REST
    '𝅂' => 1/128,          # U+1D142 M. S. ONE HUNDRED TWENTY-EIGHTH REST
);
my $note_symbol_pattern = '[' . join('', keys %note_symbols) . ']';

# This deserves a separate routine so that it can be thoroughly tested.
# I'd expect that I want to add even more weird stuff to the notation.
sub parse_note ($note_string) {
    $note_string =~
        m{^
          (?<base>[A-G])           # The plain note name
          (?<modifier>[b♭#♯]?)     # up or down half a note, Unicode or ASCII
          (?<octave>[\d]|-1)       # We don't want to support the tenth octave
          :                        # Separates pitch from duration
          (?:                      # durations come in two flavors
              (?<symbol>$note_symbol_pattern) (?<dot>$note_dot?)
          |
              (?<digits>[0-9\/.]*) # 1/4 or 0.5
          )
          $
     }ix;
    my ($base,$modifier,$octave,$symbol,$duration,$dot);
    if (my $digits = $+{digits}) {
        $duration = eval $digits;
    }
    else {
        if (my $found = $note_symbols{$+{symbol}}) {
            $duration = $found;
        }
        else {
            croak "Invalid score: No duration in '$note_string'";
        }
        if ($dot) {
            $duration *= 1.5;
        }
    }
    return ($+{base}, $+{modifier}, $+{octave}, $duration)
}

# Calculate the frequency of a note given by name, in equal-tempered
# tuning
sub named_note2frequency ($note) {
    my ($base,$modifier,$octave,$duration) =
        parse_note($note);
    my $number = $diatonic_notes{$base}
        + $diatonic_modifiers{$modifier}
        + ($octave+1) * 12;
    return (2 * A440 * (HALFTONE**($number-69)), $duration);
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
