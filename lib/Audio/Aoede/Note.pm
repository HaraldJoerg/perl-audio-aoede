# Abstract: A single (music) note with a name
package Audio::Aoede::Note;  # for tools which don't grok class

use 5.036;
use utf8; # for the unicode MUSICAL SYMBOL stuff
use warnings;
use feature 'signatures';
no warnings 'experimental';

use Feature::Compat::Class;

class Audio::Aoede::Note;

use Carp;

field $name       :reader :param;
field $accidental :reader :param = '';
field $octave     :reader :param = undef;
field $duration   :reader :param = undef;
field $timbre     :reader;

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


method set_duration ($new) {
    $duration = $new;
    return $self;
}


method set_octave ($new) {
    $octave = $new;
    return $self;
}


method set_timbre ($new) {
    $timbre = $new;
    return $self;
}


method midi_number {
    defined $octave  or  croak("Error: MIDI numbers need an octave");
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

This class represents a single note.  The purpose is to convert from a
text representation ("Scientific Pitch Notation") to a MIDI number
which then can be converted to a pitch by some tuning.  Notes can be
assigned a L<timbre|Audio::Aoede::Timbre>.

=head1 METHODS

=over

=item C<< $note = Audio::Aoede::Note->from_spn($string) >>

The usual constructor for Audio::Aoede::Note objects.  C<$string> is a
note in Scientific Pitch Notation consisting of a name, an optional
accidental and an optional octave.

The name is an uppercase a letter in the range C<A> to C<G>.  The
accidental can be given as a unicode musical symbol or its ASCII
replacement as one of C<'b'>, C<'♭'>, C<'bb'>, C<'𝄫'>, C<'#'>, C<'♯'>,
C<'##'> or C<'𝄪'>.  The octave is a number between -1 and 9
(inclusive).

=item C<< $note->set_duration($duration) >>

Sets the note's duration, in units of notes - so a quarter note has
the duration of 1/4 or 0.25.  Returns the note to allow method chaining.

=item C<< $note->set_octave($octave) >>

Sets the note's octave.  Returns the note to allow method chaining.

=item C<< $note->set_timbre($timbre) >>

Sets the note's timbre to C<$timbre> which should be an
L<Audio::Aoede::Timbre> object.  Returns the note to allow method
chaining.

=item C<< $number = $note->midi_number >>

Returns the MIDI number of the note.  Dies if the note does not have a
value for its octave.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
