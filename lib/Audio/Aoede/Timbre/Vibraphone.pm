package Audio::Aoede::Timbre::Vibraphone;
use 5.032;

use feature 'signatures';
no warnings 'experimental';

use Audio::Aoede::Timbre;
use Audio::Aoede::Envelope::ADSR;

sub vibraphone ($rate) {
    return Audio::Aoede::Timbre->new(
        harmonics => [1,1/2,1/3,1/2,0.0,0.0,0,1/2,(0)x7,1/2,(0)x15,0],
        effects => [
            sub ($frequency ) {
                return Audio::Aoede::Envelope::ADSR->new(
                    attack  => 100,
                    decay   => $rate * 2400/$frequency,
                    sustain => 0.0,
                    release => $rate/2,# * 200/$frequency,
                );
            }
        ]
    );
}

1;
