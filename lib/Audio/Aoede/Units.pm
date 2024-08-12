# ABSTRACT: Units and conversion functions
package Audio::Aoede::Units;
use 5.032;
use warnings;
use utf8; # for the note names

use feature 'signatures';
no warnings 'experimental';

use Exporter 'import';
our @EXPORT_OK = qw(
                       A440
                       CENT
                       HALFTONE
                       PI
                       rate
                       tempo
               );

use Carp;

use constant PI       => atan2(0,-1); # Math::Trig collides with PDL
use constant A440     => 440;
use constant HALFTONE => 2**(1/12);
use constant CENT     => 2**(1/1200);

# The rate (number of samples per second) should only be set once, or
# left at its default value.
my $rate = 44100;

sub rate () { return $rate };

# The tempo is a MIDI term giving the number of microseconds per
# quarter note.  This can be changed.
my $tempo = 500_000;

sub tempo () {
    return $tempo;
}

sub set_tempo ($new_tempo) {
    $tempo = $new_tempo;
}

sub set_bpm ($bpm) {
    $tempo = 6E7/$bpm;
}

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Units - constants and conversions

=head1 SYNOPSIS

This is an internal module.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
