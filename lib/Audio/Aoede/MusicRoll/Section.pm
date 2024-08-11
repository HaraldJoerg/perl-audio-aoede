# ABSTRACT: A section within a Music Roll

package Audio::Aoede::MusicRoll::Section; # for the tools

use 5.032;
use utf8; # for the unicode MUSICAL SYMBOL stuff
use warnings;
use feature 'signatures';
no warnings 'experimental';
use Feature::Compat::Class;

class Audio::Aoede::MusicRoll::Section {
    field $bpm    :param = 120;
    field $tracks :param;


    method tracks {
        return @$tracks;
    }


    method bpm {
        return $bpm;
    }
}
