# ABSTRACT: One track of an Aoede opus
package Audio::Aoede::Track;
use 5.036;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Track;

field @notes :reader = ();


method add_notes (@new) {
    push @notes,@new;
    return $self;
}

1;

__END__

=head1 NAME

Audio::Aoede::Track - One track of an Aoede opus

=head1 SYNOPSIS

  use Audio::Aoede::Track;
  my $t = Audio::Aoede::Track->new;
  $t->add_notes(@somenotes);
  $t->add_notes(@more_notes);
  # ... later
  my @notes = $t->notes;

=head1 DESCRIPTION

This class has lost most of its content and might well vanish
eventually.  Right now it is just an array disguising itself as a
class.  There are no checks what the elements of the array actually
are.

=head1 METHODS

=over

=item C<new()>

The constructor of this class takes no parameters.

=item C<< @notes = $t->notes() >>

Return the currently accumulated elements.

=item C<< $t = $t->add_notes(@notes) >>

Add the elements in C<@notes> to the list of notes.  The elements are
supposed to be L<Audio::Aoede::Note> or L<Audio::Aoede::Chord> objects.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Harald Jörg

This module is part of Audio::Aoede.  It is free software; you may
redistribute it and/or modify it under the same terms as Perl itself.
