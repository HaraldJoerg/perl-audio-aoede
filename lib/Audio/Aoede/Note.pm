# Abstract: A single (music) note
package Audio::Aoede::Note;  # for tools which don't grok class

use 5.036;
use utf8; # for the unicode MUSICAL SYMBOL stuff
use warnings;
use feature 'signatures';
no warnings 'experimental';

use Feature::Compat::Class;

class Audio::Aoede::Note;

use Carp;

use Audio::Aoede::Units qw( A440 HALFTONE );

field $name       :reader :param;
field $accidental :reader :param = '';
field $octave     :reader :param = undef;

my %diatonic_intervals = (
    C => 0,   D => 2,   E => 4,   F => 5,   G => 7,   A => 9,   B => 11,
);
my %accidental = (
    ''   =>  0,
    'b'  => -1,   '♭' => -1,
    'bb' => -2,   '𝄫' => -2,
    '#'  =>  1,   '♯' =>  1,
    '##' =>  2,   '𝄪' =>  2,
);
# my %subscripts = map { chr(ord('₀') +$_) => $_ } (0..9);  # ₀₁₂₃₄₅₆₇₈₉
my %subscripts = reverse builtin::indexed(qw (₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉));

ADJUST {
    $accidental = $accidental{$accidental}   // $accidental;
    $octave     = $subscripts{$octave // ''} // $octave;
}

# Alternate (and maybe usually used) constructor
sub from_spn ($class,$spn) {
    state $spn_pattern = qr{
              ^
              (?<name>[A-G])    # The note name
              (?<accidental>
                  bb | \#\#
              |
                  [b♭𝄫#♯𝄪] # up or down Unicode or ASCII
              )?
              (?<octave>[\d₀₁₂₃₄₅₆₇₈₉]|-1|) # We don't support the tenth octave
              $
                       }ix;
    $spn =~ $spn_pattern;
    $+{name}  or  croak("Error: No name for note '$spn' found.\n");
    my $accidental = $accidental{$+{accidental} // 0};
    my $octave = $subscripts{$+{octave}} // $+{octave};
    return $class->new(
        name       => $+{name},
        accidental => $accidental // '',
        octave     => $octave,
    )
}

method midi_number {
    $octave  or  croak("Error: MIDI numbers need an octave");
    return $diatonic_intervals{uc $name}
        + $accidental
        + ($octave+1) * 12;
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Note - a single note

=head1 DESCRIPTION

This class represents a single note.  Its constructor C<from_spn>
parses notes in "Scientific Pitch Notation" and might be useful as a
bridge to various CPAN modules which produce SPN notes.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
