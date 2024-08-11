# ABSTRACT: One voice in the Aoede Orchestra
use 5.032;
package Audio::Aoede::Voice 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Voice {
    use PDL;

    use Audio::Aoede::Note;
    use Audio::Aoede::Units qw( rate tempo );

    field $function :param;
    field $samples = pdl([]);

    method add_named_notes($notes_string) {
        my @note_strings = split " ",$notes_string; # " " strips leading spaces
        for my $note_string(@note_strings) {
            my $note = Audio::Aoede::Note->parse_note($note_string);
            my $n_samples = $note->duration() * rate() * tempo() / 250_000;
            my @pitches = $note->pitches;
            my $new_samples = @pitches ?
                sumover pdl(map {
                    $function->($n_samples,$_)
                } $note->pitches)->transpose
            :
                zeroes($n_samples);
            $samples = $samples->append($new_samples);
        }
    }


    method add_notes(@notes) {
        for my $note (@notes) {
           my $n_samples = $note->duration() * rate() * tempo() / 250_000;
            my @pitches = $note->pitches;
            my $new_samples = @pitches ?
                sumover pdl(map {
                    $function->($n_samples,$_)
                } $note->pitches)->transpose
            :
                zeroes($n_samples);
            $samples = $samples->append($new_samples);
        }
    }

    method samples() {
        return $samples;
    }
}

1;
