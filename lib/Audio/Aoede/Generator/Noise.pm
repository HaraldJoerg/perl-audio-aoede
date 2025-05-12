package Audio::Aoede::Generator::Noise;
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Generator::Noise;
use Audio::Aoede::Noise;
use Carp;
use PDL;
use constant PI => atan2(0,-1);

field $width :param = 0.1;
field $rate  :param;

method function ($frequency) {
    my $noise = Audio::Aoede::Noise->gaussian(
        rate      => $rate,
        frequency => $frequency,
        width     => $width,
    );
    return sub ($n_samples,$first = 0) {
        return $noise->next_samples($n_samples,$first);
    };
}

1;
