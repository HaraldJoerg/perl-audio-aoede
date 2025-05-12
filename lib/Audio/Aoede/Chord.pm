# Abstract: A chord of (music) note names
package Audio::Aoede::Chord;  # for tools which don't grok class

use 5.038;
use warnings;
use feature 'signatures';
no warnings 'experimental';

use Feature::Compat::Class;

class Audio::Aoede::Chord {
    field @notes;
    field $notes    :param = [];
    field $duration :reader :param = undef;
    field $timbre   :reader;

    ADJUST {
        @notes = @$notes;
        undef $notes;
    }


    method notes () {
        return @notes;
    }


    method set_duration ($new) {
        $duration = $new;
        return $self;
    }


    method set_timbre ($new) {
        $timbre = $new;
        return $self;
    }


    method midi_number () {
        return (map { $_->midi_number } @notes );
    }
}

1;

=head1 NAME

Audio::Aoede::Chord - notes with a common duration

=head1 SYNOPSIS

  use Audio::Aoede::Chord;
  my $chord = Audio::Aoede::Chord->new(
      notes => [ @notes ],
  );
  $chord->set_duration(1/4);

=head1 DESCRIPTION

This class holds notes (L<Audio::Aoede::Note> objects) which sound
simultaneously with the same duration.  The list of notes is meant to
be a list of L<Audio::Aoede::Note> objects, but this is not enforced
in any way.  The duration is expected in units of notes: a quarter
note has a duration of 1/4.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
