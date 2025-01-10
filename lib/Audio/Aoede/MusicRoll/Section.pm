# ABSTRACT: A section within a Music Roll

package Audio::Aoede::MusicRoll::Section; # for the tools

use 5.032;
use utf8; # for the unicode MUSICAL SYMBOL stuff
use warnings;
use feature 'signatures';
no warnings 'experimental';
use Feature::Compat::Class;

class Audio::Aoede::MusicRoll::Section {
    field $bpm     :param :reader = 120;
    field $tracks  :param;
    field $dynamic :param :reader = undef;

    method tracks () {
        return @$tracks;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::MusicRoll::Section - one section of a music roll

=head1 DESCRIPTION

Every section of a music roll can have its own speed and number of
tracks.

This module is just a container for internal use.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
