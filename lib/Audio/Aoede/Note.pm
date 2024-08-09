# Abstract: A single (music) note
package Audio::Aoede::Note;  # for tools which don't grok class

use 5.032;
use utf8; # for the unicode MUSICAL SYMBOL stuff
use warnings;
use feature 'signatures';
no warnings 'experimental';

use Feature::Compat::Class;

class Audio::Aoede::Note {
    use Carp;

    use Audio::Aoede::Units qw( A440 HALFTONE );

    field $duration :param;
    field $pitch    :param = undef;


    method duration () {
        return $duration;
    }


    method pitch () {
        return $pitch;
    }

    
    my %diatonic_notes = (
        C => 0,   D => 2,   E => 4,   F => 5,   G => 7,   A => 9,   B => 11,
    );
    my %diatonic_modifiers = (
        ''  =>  0,
        'b' => -1,   '♭' => -1,
        '#' =>  1,   '♯' =>  1,
    );
    my %note_symbols = (
        '𝅝' => 1,       # U+1D15D MUSICAL SYMBOL WHOLE NOTE
        '𝅗𝅥' => 1/2,     # U+1D15E MUSICAL SYMBOL HALF NOTE
        '𝅘𝅥' => 1/4,     # U+1D15F MUSICAL SYMBOL QUARTER NOTE
        '𝅘𝅥𝅮' => 1/8,     # U+1D160 MUSICAL SYMBOL EIGHTH NOTE
        '𝅘𝅥𝅯' => 1/16,    # U+1D161 MUSICAL SYMBOL SIXTEENTH NOTE
        '𝅘𝅥𝅰' => 1/32,    # U+1D162 MUSICAL SYMBOL THIRTY-SECOND NOTE
        '𝅘𝅥𝅱' => 1/64,    # U+1D163 MUSICAL SYMBOL SIXTY-FOURTH NOTE
        '𝅘𝅥𝅲' => 1/128,   # U+1D164 M. S. ONE HUNDRED TWENTY-EIGHTH NOTE
    );
    my $note_symbol_pattern = '[' . join('', keys %note_symbols) . ']';
    my $note_dot = '𝅭'; # U+1D16D MUSICAL SYMBOL COMBINING AUGMENTATION DOT

    my %rest_symbols = (
        '𝄻' => 1,       # U+1D13B MUSICAL SYMBOL WHOLE REST
        '𝄼' => 1/2,     # U+1D13C MUSICAL SYMBOL HALF REST
        '𝄽' => 1/4,     # U+1D13D MUSICAL SYMBOL QUARTER REST
        '𝄾' => 1/8,     # U+1D13E MUSICAL SYMBOL EIGHTH REST
        '𝄿' => 1/16,    # U+1D13F MUSICAL SYMBOL SIXTEENTH REST
        '𝅀' => 1/32,    # U+1D140 MUSICAL SYMBOL THIRTY-SECOND REST
        '𝅁' => 1/64,    # U+1D141 MUSICAL SYMBOL SIXTY-FOURTH REST
        '𝅂' => 1/128,   # U+1D142 M. S. ONE HUNDRED TWENTY-EIGHTH REST
    );
    my $rest_symbol_pattern = '[' . join('', keys %rest_symbols) . ']';

    sub parse_note ($class,$note_string) {
        $note_string =~
            m{^
              (?<base>[A-G])       # The plain note name
              (?<modifier>[b♭#♯]?) # up or down half a note, Unicode or ASCII
              (?<octave>[\d]|-1)   # We don't want to support the tenth octave
              :                    # Separates pitch from duration
              (?:                  # durations come in two flavors
                  (?<symbol>$note_symbol_pattern) (?<dot>$note_dot?)
              |
                  (?<digits>(?&DIGITS))
              )
          |
              (?:                  # Rests also come in two flavors
                  (?<rest_symbol>$rest_symbol_pattern)
              |
                  (?<base>R)
                  :
                  (?<digits>(?&DIGITS))
              )
              $
              (?(DEFINE)
                  (?<DIGITS>[0-9\/.]*) # 1/4 or 0.5
              )
         }ix;
        my ($symbol,$duration,$dot);
        my $base = $+{base} // 'R'; # undefined in case of a rest symbol
        if (my $digits = $+{digits}) {
            $duration = eval $digits;
        } else {
            if ($+{symbol} && $note_symbols{$+{symbol}}) {
                $duration = $note_symbols{$+{symbol}};
            } elsif (my $rest = $+{rest_symbol}) {
                $duration = $rest_symbols{$rest};
            } else {
                croak "Invalid score: No duration in '$note_string'";
            }
            if ($dot) {
                $duration *= 1.5;
            }
        }
        my $number = $diatonic_notes{$base}
            + $diatonic_modifiers{$+{modifier}}
            + ($+{octave}+1) * 12;
        my $pitch = 2 * A440 * (HALFTONE**($number-69));
        return __PACKAGE__->new(
            duration => $duration,
            pitch    => $pitch
        );
    }
}
