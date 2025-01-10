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

method function ($frequency) {
    return sub ($n_samples,$rate,$first = 0) {
        my $noise = Audio::Aoede::Noise->gaussian(
            frequency => $frequency,
            width     => $width,
        );
        return $noise->samples($n_samples,$first);
    };
}

1;
