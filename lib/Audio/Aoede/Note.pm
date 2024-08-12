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
