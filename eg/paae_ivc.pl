use 5.032;

use feature 'signatures';
no warnings 'experimental';

use Audio::Aoede::Timbre::Vibraphone;
use Audio::Aoede::Effects::Percussive;
use Audio::Aoede::Envelope::ADSR;
use Audio::Aoede::Generator::Noise;
use Audio::Aoede::Generator::Sine;

my $A = Audio::Aoede->new;
my $rate = 44100;
my $vibrato = $A->vibrato (width => 0.0, frequency => 3);
my $tremolo = $A->tremolo (width => 0.05, frequency => 2);

my $t_organ = Audio::Aoede::Timbre->new(
    generator => Audio::Aoede::Generator::Sine->new(
        vibrato => $vibrato,
        tremolo => $tremolo,
    ),
    harmonics => [1,0.5,0.5,0.5,0.2,0.1],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 200,
                decay   => $rate,
                sustain => 0,
                release => 100,
            );
        }
    ]
);

my $t_vibra = Audio::Aoede::Timbre::Vibraphone::vibraphone($rate);

my $t_h_effect = Audio::Aoede::Timbre->new(
    generator => Audio::Aoede::Generator::Sine->new(),
    harmonics => [0.1],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Effects::Percussive->new(
                frequency => $frequency,
                intensity => 0.1,
                width => 1.5,
                duration => 5000,
            )
        },
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 100,
                decay   => $rate,
                sustain => 0,
                release => 10000,
            );
        }
    ]
);

my @res =
(
    { timbre    => $t_vibra,
      channels  => { left => 3.0, right => 1.0 },
  },
    { timbre => $t_organ,
      channels => { left => 1.0, right => 2.0 },
  },
    { timbre => $t_organ,
      channels => { left => 2.0, right => 1.0 },
  },
    { timbre   => $t_h_effect,
      channels => { left => 1.0, right => 0.5 },
  },
);
