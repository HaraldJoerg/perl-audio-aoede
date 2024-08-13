# ABSTRACT: An envelope for Aoede voices
package Audio::Aoede::Envelope;
use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Envelope {
    use PDL;

    method apply ($samples) {
        return $samples;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Envelope - a null volume envelope

=head1 SYNOPSIS

  use Audio::Aoede::Envelope;
  $envelope = Audio::Aoede::Envelope->new();
  $envelope->apply($samples); # returns $samples unchanged

=head1 DESCRIPTION

Quoted from Wikipedia: "In sound and music, an envelope describes how
a sound changes over time".  A plucked guitar string creates an
initial sound almost immediately, and then continually fades away
until zero, or until mechanically damped by the player.

This envelope does nothing, it returns the input samples unchanged.

=head2 METHODS

=over

=item C<< $env = Audio::Aoede::Envelope->new(%params) >>

Creates a new envelope object.

=item C<< ($mod_samples,$carry) = $env->apply($samples) >>

Apply the envelope to C<$samples>.  Or rather, don't.
Just return the samples as they were.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
