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
    harmonics => [1,0.5,0.5,0.5,0.2,0.1],#1/3,1,1/5,0.0,0.0,1,(0)x7,1/2,(0)x15,0.5],
    effects => [
        sub ($frequency) {
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => 1/200,
                decay   => 1,
                sustain => 0,
                release => 1/500,
            );
        }
    ]
);

my $t_vibra = Audio::Aoede::Timbre::Vibraphone::vibraphone();

my @res =
(
    { timbre    => $t_vibra,
      channels  => { left => 2.0, right => 1.0 },
  },
    { timbre => $t_organ,
      channels => { left => 1.0, right => 2.0 },
  },
    { timbre => $t_vibra,
      channels => { left => 2.0, right => 1.0 },
  },
    { timbre   => $t_vibra,
      channels => { left => 3.0, right => 1.0 },
  },
);
