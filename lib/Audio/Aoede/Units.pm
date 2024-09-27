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
                       cB
                       dB
                       default_tempo
                       hz2mel
                       mel2hz
                       seconds_per_note
               );

use Carp;

use constant A440     => 440;
use constant PI       => atan2(0,-1); # Math::Trig collides with PDL
use constant HALFTONE => 2**(1/12);
use constant CENT     => 2**(1/1200);
use constant dB       => 2**(1/10);
use constant cB       => 2**(1/100);

sub seconds_per_note ($bpm) {
    return 240/$bpm;
}

# The tempo is a MIDI term giving the number of microseconds per
# quarter note.  This can be changed.  We actually want to avoid this
# unit and use beats per minute whereever applicable.
my $default_tempo = 500_000;

sub default_tempo () {
    return $default_tempo;
}

sub tempo ($bpm) {
    return 6E7/$bpm;
}

# Conversion between frequency and mel scale
# Source: Douglas O'Shaughnessy (1987).
# Speech communication: human and machine.
# Addison-Wesley. p. 150. ISBN 978-0-201-16520-3
# https://books.google.com/books?id=mHFQAAAAMAAJ&q=2595
# The formula is adapted to use the natural logarithm,
# in the book the logarithm is base 10
#
# This is not used in the code, but I would like to have the
# definition and its source ready.

sub hz2mel ($hz) {
    return 1127 * log(1 + $hz/700);
}

sub mel2hz ($mel) {
    return 700 * (exp($mel/1127) - 1);
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
