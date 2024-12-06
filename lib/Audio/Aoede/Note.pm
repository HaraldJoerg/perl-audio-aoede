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

    field $duration :param = 0;
    field $pitches  :param = [];
    field $spn      :param = '';
    field @pitches;

    ADJUST {
        @pitches = @$pitches;
        undef $pitches;
        if (! @pitches) {
            @pitches = map {
                from_spn($_)
            } split /\s*\+\s*/,$spn;
        }
    }

    method duration () {
        return $duration;
    }


    method pitches () {
        return @pitches;
    }

    # FIXME: This is duplicate code, it also appears in the MusicRoll
    # parser.  I should decide where I want that stuff, but do not
    # want to right now.
    my %diatonic_notes = (
        C => 0,   D => 2,   E => 4,   F => 5,   G => 7,   A => 9,   B => 11,
    );
    my %diatonic_modifiers = (
        ''   =>  0,
        'b'  => -1,   '♭' => -1,
        'bb' => -2,   '𝄫' => -2,
        '#'  =>  1,   '♯' =>  1,
        '##' =>  2,   '𝄪' =>  2,
    );
    my $spn_pattern =
        qr{
              (?<base>[A-G])    # The base note name
              (?<modifier>
                  [b♭𝄫#♯𝄪] # up or down Unicode or ASCII
              |
                  bb | \#\#
              )?
              (?<octave>[\d]|-1) # We don't support the tenth octave
      }ix;

    sub from_spn ($spn) {
        $spn =~ $spn_pattern;
        return unless $+{base};
        my $octave = $+{octave};
        my $number = $diatonic_notes{uc $+{base}}
            + $diatonic_modifiers{$+{modifier} // ''}
            + ($octave+1) * 12;
        return A440 * (HALFTONE**($number-69));
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Note - a single piece of sound

=head1 DESCRIPTION

Right now, this module is a container without function and should be
considered for internal use only.  For a start, the name is a bit off
because one object of this class can hold a complete chord.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
