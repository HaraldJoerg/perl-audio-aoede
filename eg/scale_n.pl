# A non-physical sound
use feature 'signatures';
no warnings 'experimental';
use Audio::Aoede::Timbre;
my $A = Audio::Aoede->new;
my $rate    = $A->rate;
my $vibrato = $A->vibrato (width => 5, frequency => 3);
my $tremolo = $A->tremolo (width => 0.2, frequency => 2);
return (
    {
        timbre => Audio::Aoede::Timbre->new(
            generator => Audio::Aoede::Generator::Sine->new(
                rate    => $rate,
                vibrato => $vibrato,
                tremolo => $tremolo,
            ),
            harmonics => [1.0,0.5,0.5,0.5,0.5,0.5,0.5,1.0,1.0],
            effects => [
                sub ($frequency) {
                    return Audio::Aoede::Envelope::ADSR->new(
                        attack  => 1/10,
                        decay   => $frequency/2000,
                        sustain => 0.0,
                        release => $frequency/1500,
                    );
                },
            ]
        ),
        channels  => { left => 0.5, right => 0.5 },
    }
);
