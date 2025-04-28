# ABSTRACT: Some MIDI constants for Aoede
package Audio::Aoede::MIDI;
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::MIDI;

# https://en.wikipedia.org/wiki/General_MIDI_Level_2
my %controllers = (
    0   => 'Bank Select (MSB)',
    1   => 'Modulation Wheel',
    2   => 'Breath Controller',
    4   => 'Foot Controller',
    5   => 'Portamento Time',
    6   => 'Data Entry (MSB)',
    7   => 'Channel Volume',
    10  => 'Pan',
    32  => 'Bank Select (LSB)',
    38  => 'Data Entry (LSB)',
    64  => 'Damper Pedal On/Off (Sustain)',
    65  => 'Portamento On/Off',
    66  => 'Sostenuto On/Off',
    67  => 'Soft Pedal On/Off',
    70  => 'Sound Variation',
    71  => 'Timbre/Harmonic Intensity (filter resonance)',
    72  => 'Release Time',
    73  => 'Attack Time',
    74  => 'Brightness (cutoff frequency)',
    75  => 'Decay Time',
    76  => 'Vibrato Rate',
    77  => 'Vibrato Depth',
    78  => 'Vibrato Delay',
    91  => 'Effect 1 Depth (reverb send level)',
    92  => 'Effect 2 Depth (formerly tremolo depth)',
    93  => 'Effect 3 Depth (chorus send level)',
    94  => 'Effect 4 Depth (formerly detune depth)',
    95  => 'Effect 5 Depth (formerly phaser depth)',
    100 => 'Registered Parameter Number (MSB)',
    101 => 'Registered Parameter Number (LSB)',
);

1;

__END__

=head1 NAME

Audio::Aoede::MIDI - some MIDI constants

=head1 SYNOPSIS

  ...nothing useful here yet.


=head1 DESCRIPTION

The MIDI modules on CPAN help with parsing, but they do not actually
help interpreting.  Here's some mappings from numbers used in MIDI
messages to meaning.  This module is not used yet at all.

=cut

