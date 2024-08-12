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
        return;
    }

    method sections {
        return @sections;
    }

}
1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::MusicRoll - A class representing a music roll

=head1 SYNOPSIS

  use Audio::Aoede::MusicRoll;
  $music_roll = Audio::Aoede::MusicRoll->from_file($path);

=head1 DESCRIPTION

Objects of this class represent a music roll.  A music roll is a
container without functions.  It contains a list of sections, see
L<Audio::Aoede::MusicRoll::Section>.

=head1 METHODS

=over

=item C<$music_roll = from_file($path)>

Create a new music roll from a
L<Audio::Aoede::MusicRoll::Format|MRT file>.
Dies if the file can not be processed.

=item C<< $music_roll->add_section >>

Add a L<Audio::Aoede::MusicRoll::Section|section> to the music roll.

=item C<< @sections = $music_roll->sections >>

Return the list of sections.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This document is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

