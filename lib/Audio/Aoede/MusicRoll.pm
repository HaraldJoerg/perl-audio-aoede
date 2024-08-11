# ABSTRACT: A Perl class representing a music roll
package Audio::Aoede::MusicRoll;
use 5.032;
use feature 'signatures';
use warnings;
no warnings 'experimental';
use Feature::Compat::Class;

class Audio::Aoede::MusicRoll {
    field @sections;

    sub from_file ($class,$path) {
        require Audio::Aoede::MusicRoll::Parser;
        return Audio::Aoede::MusicRoll::Parser::parse_file($path);
    }

    method add_section ($section) {
        push @sections,$section;
    }

    method sections {
        return @sections;
    }

}
1;
