use 5.032;

use feature 'signatures';
no warnings 'experimental';

use Audio::Aoede::Timbre::Vibraphone;

my $A = Audio::Aoede->new;
my $vibrato = $A->vibrato (width => 0.0, frequency => 3);
my $tremolo = $A->tremolo (width => 0.05, frequency => 2);

my $t_organ = Audio::Aoede::Timbre->new(
    generator => Audio::Aoede::Generator::Sine->new(
        vibrato => $vibrato,
        tremolo => $tremolo,
    ),
    harmonics => [1,1,1/3,1,1/5,0.0,0.0,1,(0)x7,1/2,(0)x15,0.5],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 1/50,
                decay   => 0,
                sustain => 1,
                release => 1/500,
            );
        }
    ]
);

my $t_organ2 = Audio::Aoede::Timbre->new(
    generator => Audio::Aoede::Generator::Sine->new(
        vibrato => $A->vibrato (width => 0.5, frequency => 4),
        tremolo => $A->tremolo (width => 0., frequency => 4),
    ),
    harmonics => [1,1,1/3,1,1/5,0.0,0.0,1,(0)x7,1/2,(0)x15,0.5],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 1/50,
                decay   => 0,
                sustain => 1,
                release => 1/500,
            );
        }
    ]
);

my $t_gnomus = Audio::Aoede::Timbre->new(
    generator => Audio::Aoede::Generator::Sine->new(
        vibrato => $A->vibrato (width => 0.1, frequency => 3),
    ),
    harmonics => [1.0,0.5,1.0,0.5,1.0,1.0,(0.0)x8,1,1,1,1,1],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 1/500,
                decay   => 1,
                sustain => 0.0,
                release => 1/4,
            );
        }
    ]
);

my $t5 = Audio::Aoede::Timbre->new(
    generator => Audio::Aoede::Generator::Sine->new(
        vibrato => $A->vibrato(width => 0.5, frequency => 3),
    ),
    harmonics => [1.0,0.5,0.333],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 1/500,
                decay   => 2400/$frequency,
                sustain => 0,
                release => 1/2,
            );
        }
    ]
);



my @res =
(
    { timbre    => Audio::Aoede::Timbre::Vibraphone::vibraphone(),
      channels  => { left => 3.0, right => 1.0 },
  },
    { timbre => $t_organ,
      channels => { left => 0.0, right => 1.0 },
  },
    { timbre => $t_organ2,
      channels => { left => 0.75, right => 0.25 },
  },
    { timbre   => $t_gnomus,
      channels => { left => 1.0, right => 3.0 },
  },
    { timbre   => $t5,
      channels => { left => 1.0, right => 0.5 },
  }
);
