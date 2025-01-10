use 5.032;

use feature 'signatures';
no warnings 'experimental';

use Audio::Aoede::Timbre;
use Audio::Aoede::Timbre::Vibraphone;

my $A = Audio::Aoede->new;
my $rate = $A->rate;
#my $vibrato = $A->vibrato (width => 0.0, frequency => 3);
#my $tremolo = $A->tremolo (width => 0.05, frequency => 2);

my $t_back_organ = Audio::Aoede::Timbre->new(
    harmonics => [1,1/2,1/3,1,1/5,0.0,0.0,1,(0)x7,0.1,(0)x15,0.1],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 1200,
                decay   => 2*$rate,
                sustain => 0.1,
                release => 100,
            );
        }
    ]
);

my $t_back_guitar = Audio::Aoede::Timbre->new(
    harmonics => [1,1/2,1/3,1,1/5,0.0,0.0,1,(0)x7,0.1,(0)x15,0.1],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 100,
                decay   => $rate * 2400/$frequency,
                sustain => 0,
                release => $rate/4,
            );
        }
    ]
);

my $t_melody_organ = Audio::Aoede::Timbre->new(
    harmonics => [1,1,1/3,1,1/5,0.0,0.0,1],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 1200,
                decay   => 2*$rate,
                sustain => 0.3,
                release => 100,
            );
        }
    ]
);

my $t_melody_voice = Audio::Aoede::Timbre->new(
    harmonics => [1,1/2,1/3,1/4,(0)x5,1/4,1/4],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 1200,
                decay   => 4*$rate,
                sustain => 0.3,
                release => 100,
            );
        }
    ]
);

my @res =
(
    { timbre    => $t_melody_organ,
      channels  => { left => 0.5, right => 1.5 },
  },
    { timbre    => $t_back_organ,
      channels  => { left => 0.5, right => 0.5 },
  },
    { timbre    => $t_back_organ,
      channels  => { left => 0.25, right => 0.25 },
  },
    { timbre    => $t_back_guitar,
      channels  => { left => 0.5, right => 0.5 },
  },
    { timbre    => $t_melody_voice,
      channels  => { left => 1.0, right => 0.2 },
  },
);
