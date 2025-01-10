package Audio::Aoede::Generator::Sine;
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Generator::Sine;

use Carp;
use PDL;
use constant PI => atan2(0,-1);

field $vibrato :param = undef;
field $tremolo :param = undef;

method function ($frequency) {
    return sub ($n_samples,$rate,$first = 0) {
        my $samples_per_period = $rate / $frequency;
        my $norm = 2 * PI() / $samples_per_period;
        $first -= $samples_per_period * int $first/$samples_per_period;
        my $phase = (sequence($n_samples) + $first) * $norm;
        if ($vibrato) {
            my $samples_per_vperiod = $rate / $vibrato->frequency;
            my $vnorm = 2 * PI() / $samples_per_vperiod;
            my $vshift = $first
                - ($samples_per_vperiod * int($first/$samples_per_vperiod));
            my $vphase = (sequence($n_samples) + $vshift) * $vnorm;
            $phase += $vibrato->width * $vphase->sin;
        }
        my $samples = $phase->sin;
        if ($tremolo) {
            my $samples_per_tperiod = $rate / $tremolo->frequency;
            my $tnorm = 2 * PI() / $samples_per_tperiod;
            my $tshift = $first
                - ($samples_per_tperiod * int($first/$samples_per_tperiod));
            my $tphase = (sequence($n_samples) + $tshift) * $tnorm;
            $samples *= (1 + $tremolo->width * $tphase->sin);
        }
        return $samples;
    };
}

1;
