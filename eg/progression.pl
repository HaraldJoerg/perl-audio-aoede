use 5.036;
use utf8;
use feature 'signatures';
use experimental qw(for_list);
no warnings 'experimental';

use Audio::Aoede;
use Audio::Aoede::Chord;
use Audio::Aoede::Note;
use Music::Chord::Progression;
use Music::Scales qw( get_scale_notes );
use PDL;

my @melody;
my $duration = 1/4;

# get 4 notes of the C pentatonic scale
my @pitches = get_scale_notes('C', 'pentatonic');
my @notes = map { $pitches[int rand @pitches] } 1 .. 4;

# play the 8-bar progression for each note
for my $note (@notes) {
    my $prog = Music::Chord::Progression->new(
        scale_note => $note,
    );
    my $chords = $prog->generate;
    push @melody, map {
        Audio::Aoede::Chord->new(
            notes => [map { Audio::Aoede::Note->from_spn($_) } @$_ ],
            duration => $duration,
        );
    } @$chords;
}
my $A = Audio::Aoede->new();#out => 'progression.ogg');
$A->play_notes(@melody);
