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
    field $pitches  :param = [];
    field @pitches;

    ADJUST {
        @pitches = @$pitches;
        undef $pitches;
    }

    method duration () {
        return $duration;
    }


    method pitches () {
        return @pitches;
    }

}
