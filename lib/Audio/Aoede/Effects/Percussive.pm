# ABSTRACT: Start a tone/sound with inharmonic noise
use 5.038;
package Audio::Aoede::Effects::Percussive;

use Feature::Compat::Class;
no warnings 'experimental';

class Audio::Aoede::Effects::Percussive;

use PDL;

use Audio::Aoede;
use Audio::Aoede::Noise;

field $frequency :param;
field $width     :param;
field $duration  :param;
field $intensity :param;
field $noise;

ADJUST {
    my $rate = Audio::Aoede->instance->rate;
    $duration = int ($rate * $duration); # Switch from seconds to samples
    my $dummy = zeroes($duration);
    my $amplitude = $dummy->xlinvals(1.0,0.0) * $intensity;
    $noise = Audio::Aoede::Noise->gaussian(
        frequency => $frequency,
        width     => $width,
    )->samples($duration,0) * $amplitude;
}


sub generate ($class,$min,$max,$duration) {
    $class->new(
        min_frequency => $min,
        max_frequency => $max,
        duration      => $duration,
    );
}


method apply ($samples,$offset) {
    my $todo = $duration - $offset;
    if ($todo < 0) {
        return $samples;
    }
    else {
        my $n_samples = $samples->dim(0);
        if ($n_samples > $todo) {
            $samples->slice([0,$todo-1]) += $noise->slice([$offset,$duration-1]);
        }
        else {
            $samples += $noise->slice([$offset,$offset+$n_samples-1]);
        }
        return $samples;
    }
}


method release ($offset) {
    return pdl([]);
}

1;
