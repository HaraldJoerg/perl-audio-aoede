# ABSTRACT: Units and conversion functions
package Audio::Aoede::Units;
use 5.032;
use warnings;
use utf8; # for the IPA vowels

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
                       seconds_per_timecent
                       timecents_per_second
                       symbol
               );

use Carp;

use constant A440     => 440;
use constant PI       => atan2(0,-1); # Math::Trig collides with PDL
use constant HALFTONE => 2**(1/12);
use constant CENT     => 2**(1/1200);
use constant dB       => 10**(1/10);
use constant cB       => 10**(1/100);

sub seconds_per_note ($bpm) {
    return 240/$bpm;
}

# "Absolute Timecents" are a weird time scale used in soundfont files.
# An absolute timecent value of 0 corresponds to 1 second.
sub seconds_per_timecent ($tc) {
    return CENT**$tc;
}

sub timecents_per_second ($s) {
    return log($s) / log(CENT);
}

# The tempo is a MIDI term giving the number of microseconds per
# quarter note.  This can be changed.  We actually want to avoid this
# unit and use beats per minute whereever applicable.
use constant default_tempo => 500_000;

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


# Conversion between frequency and BARK (another weird unit for
# pitches)
# Source: Introduction to Praat by Dr. François Conrad
sub hz2bark ($hz) {
    return (26.81 / (1 + 1960/$hz)) - 0.53;
}


# From: https://www.compart.com/en/unicode/block/U+2300
my %symbols = (
    "REVERSE" => chr(0x23F4),
    "PLAY"    => chr(0x23F5),
    "PAUSE"   => chr(0x23F8),
    "STOP"    => chr(0x23F9),
    "RECORD"  => chr(0x23FA),
    "POWER"   => chr(0x23FB),
    "LOOP"    => chr(0x27F3),
    "MUTE"    => chr(0x1F507),
    "SPEAKER" => chr(0x1F508),
);

sub symbol ($name) {
    return ($symbols{$name} // chr(0xFFFD));
}


# This is just for documentation.  Elements of a constant hash are
# ... not really accessible.
# Source: Wikipedia
use constant vowels => (
    i => [240,2400],
    y => [235,2100],
    e => [390,2300],
    ø => [370,1900],
    ɛ => [610,1900],
    œ => [585,1710],
    a => [850,1610],
    ɶ => [820,1530],
    ɑ => [750, 940],
    ɒ => [700, 760],
    ʌ => [600,1170],
    ɔ => [500, 700],
    ɤ => [460,1310],
    o => [360, 640],
    ɯ => [300,1390],
    u => [250, 595],
);

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
