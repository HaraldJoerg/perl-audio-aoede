# ABSTRACT: A parser for MRT files
package Audio::Aoede::MusicRoll::Parser; # for the tools

use 5.032;
use utf8;                       # for the unicode MUSICAL SYMBOL stuff
use warnings;
use feature 'signatures';
no warnings 'experimental';
use autodie;                    # being lazy :)
use Feature::Compat::Class;

use Carp;

use Audio::Aoede::MusicRoll;
use Audio::Aoede::MusicRoll::Section;
use Audio::Aoede::Note;
use Audio::Aoede::Notes;
use Audio::Aoede::Track;
use Audio::Aoede::Units qw( A440 HALFTONE );

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
my %note_symbols = (
    '𝅝' => 1,           # U+1D15D MUSICAL SYMBOL WHOLE NOTE
    '𝅗𝅥' => 1/2,         # U+1D15E MUSICAL SYMBOL HALF NOTE
    '𝅘𝅥' => 1/4,         # U+1D15F MUSICAL SYMBOL QUARTER NOTE
    '𝅘𝅥𝅮' => 1/8,         # U+1D160 MUSICAL SYMBOL EIGHTH NOTE
    '𝅘𝅥𝅯' => 1/16,        # U+1D161 MUSICAL SYMBOL SIXTEENTH NOTE
    '𝅘𝅥𝅰' => 1/32,        # U+1D162 MUSICAL SYMBOL THIRTY-SECOND NOTE
    '𝅘𝅥𝅱' => 1/64,        # U+1D163 MUSICAL SYMBOL SIXTY-FOURTH NOTE
    '𝅘𝅥𝅲' => 1/128,       # U+1D164 M. S. ONE HUNDRED TWENTY-EIGHTH NOTE
);
my $note_symbol_pattern = '[' . join('', keys %note_symbols) . ']';
my $note_dot = '𝅭'; # U+1D16D MUSICAL SYMBOL COMBINING AUGMENTATION DOT

my %rest_symbols = (
    '𝄻' => 1,           # U+1D13B MUSICAL SYMBOL WHOLE REST
    '𝄼' => 1/2,         # U+1D13C MUSICAL SYMBOL HALF REST
    '𝄽' => 1/4,         # U+1D13D MUSICAL SYMBOL QUARTER REST
    '𝄾' => 1/8,         # U+1D13E MUSICAL SYMBOL EIGHTH REST
    '𝄿' => 1/16,        # U+1D13F MUSICAL SYMBOL SIXTEENTH REST
    '𝅀' => 1/32,        # U+1D140 MUSICAL SYMBOL THIRTY-SECOND REST
    '𝅁' => 1/64,        # U+1D141 MUSICAL SYMBOL SIXTY-FOURTH REST
    '𝅂' => 1/128,       # U+1D142 M. S. ONE HUNDRED TWENTY-EIGHTH REST
);
my $rest_symbol_pattern = '[' . join('', keys %rest_symbols) . ']';

my %key_map = (
    '𝅘𝅥' => 'bpm'
);

my @dynamic_markings = qw( fff ff f mf mp p pp ppp);
my $dynamic_pattern = join '|',@dynamic_markings;

my $note_pattern =
    qr{
          ^
          (?:
              (?:             # durations come in two flavors
                  (?<symbol>$note_symbol_pattern) (?<dot>$note_dot?)
              |
                  (?<digits>(?&DIGITS))
              )
              :               # Separates pitch from duration
          )?                  # No duration means: Take the previous one
          (?<notes>(?&NOTE)(?:\+(?&NOTE))*)
      |
          (?:                 # Rests also come in two flavors
              (?<rest_symbol>$rest_symbol_pattern)
          |
              (?:
                  (?<digits>(?&DIGITS))
                  :
              )?
              (?<base>R)
          )
      |
          (?<bar>[|𝄀])
      |
          (?<repeat_start> \|\|: | 𝄆 )
      |
          (?<repeat_end> :\|\| | 𝄇 )
          $
          (?(DEFINE)
              (?<DIGITS>[0-9\/.]+) # 1/4 or 0.5
              (?<NOTE>
                  [A-G]        # The base note name
                  (?:
                      bb | \#\#
                  |
                      [b♭𝄫#♯𝄪] # up or down Unicode or ASCII
                  )?
                  (?:[\d]|-1)? # We don't support the tenth octave
              )
          )
          #          |
          #              (?<bar>[|𝄀])
          #          |
          #              (?<repeat_start> \|\|: | 𝄆 )
          #          |
          #              (?<repeat_end> :\|\| | 𝄇 )
  }ix;
my $comment_pattern = qr{ ^ \# }x;
my $command_pattern = qr{ ^ ! (?<command>\w+) (\s+ (?<params>.*))? }x;

sub parse_file ($path) {
    my %params = (bpm => 120, tracks => 1, dynamic => 'mf');
    my @tracks;
    my $current_track = 0;
    my $music_roll = Audio::Aoede::MusicRoll->new();
    open (my $score, '<:encoding(UTF-8)', $path);
  LINE:
    while (my $line = <$score>) {
        next LINE if ($line !~ /\S/);
        next LINE if ($line =~ /$comment_pattern/);
        $line =~ /$command_pattern/  and  do {
            # We have a new section, so close the old one
            $current_track = 0;
            if (@tracks) {
                $music_roll->add_section(
                    Audio::Aoede::MusicRoll::Section->new(
                        bpm => $params{bpm},
                        tracks => [@tracks],
                        dynamic => $params{dynamic},
                    )
                );
            }
            my $command = $+{command};
            $command eq 'set'  and  do {
                my @settings = split /\s*;\s*/,$+{params};
                %params = (%params, map {
                    my ($key,$value) = split /\s*=\s*/,$_,2;
                    $key = $key_map{$key} // $key;
                    ($key,$value);
                } @settings);
            };
            @tracks = (map { Audio::Aoede::Track->new() }
                       (1..$params{tracks}));
            $command =~ m/$dynamic_pattern/  and  do {
                $params{dynamic} = $command;
            };
            next LINE;
        };
        # Now we know we have a notes line
        my @tokens = split /\s+/, $line;
        my $previous_duration;
        my $previous_octave;
        my @notes = map {
            my $note_string = $_;
            my $note;
            $note_string =~ /$note_pattern/  and  do {
                if (my $bar = $+{bar} || $+{repeat_start} || $+{repeat_start}) {
                    # Dealing with bars is postponed...
                }
                else {
                    my $duration;
                    if (my $digits = $+{digits}) {
                        $duration = eval $digits;
                    } else {
                        if (my $symbol = $+{symbol}) {
                            $duration = $note_symbols{$symbol};
                        } elsif (my $rest = $+{rest_symbol}) {
                            $duration = $rest_symbols{$rest};
                        } elsif ($previous_duration) {
                            $duration = $previous_duration;
                        } else {
                            croak "Invalid score: No duration in '$note_string'";
                        }
                        if ($+{dot}) {
                            $duration *= 1.5;
                        }
                    }
                    $previous_duration = $duration;
                    if ($+{notes}) {
                        my @notes = split /\+/,$+{notes};
                        my @n = map {
                            Audio::Aoede::Note->from_spn($_)
                        } @notes;
                        my @pitches = map {
                            m/(?<base>[A-G])
                              (?<modifier>[b♭#♯]*) #
                              (?<octave>[\d]|-1)?
                             /ix;
                            my $octave = $+{octave} // $previous_octave;
                            my $number = $diatonic_notes{$+{base}}
                                + $diatonic_modifiers{$+{modifier}}
                                + ($octave+1) * 12;
                            $previous_octave = $octave;
                            my $pitch = A440 * (HALFTONE**($number-69));
                        } @notes;
                        $note = Audio::Aoede::Notes->new(
                            duration => $duration,
                            pitches  => \@pitches,
                        );
                    } else {
                        # No note => Treat it as a rest
                        $note = Audio::Aoede::Notes->new(
                            duration => $duration,
                        );
                    }
                }
            };
            $note // ();
        } @tokens;
        $tracks[$current_track]->add_notes(@notes);
        $current_track += 1;
        $current_track %= $params{tracks};
    }
  FINALIZE:                  # All lines read, process current section
    $music_roll->add_section(
        Audio::Aoede::MusicRoll::Section->new(
            bpm => $params{bpm},
            tracks => [@tracks],
            dynamic => $params{dynamic},
        )
    );
    return $music_roll;
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::MusicRoll::Parser - parse MRT files

=head1 SYNOPSIS

  use Audio::Aoede::MusicRoll::Parser;
  my $music_roll = Audio::Aoede::MusicRoll::Parser::parse_file($path);

=head1 DESCRIPTION

Parse a L<MRT file|Audio::Aoede::MusicRoll::Format> into a
L<Audio::Aoede::MusicRoll> object.

=head1 SUBROUTINES

This module has only one subroutine.

=over

=item C<< $music_roll = parse_file($path) >>

Read a file from C<$path> and create a L<Audio::Aoede::MusicRoll>
object from its contents.

Dies when it sees stuff it does not understand.  The error messages
are not very helpful, I'm afraid.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
