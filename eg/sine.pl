use 5.032;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Voice::Sine {
    use PDL;
    use constant pi => atan2(0,-1); # Math::Trig collides with PDL

    use Audio::Aoede;

    field $frequency :param;
    field $samples_per_period = Audio::Aoede->rate / $frequency;
    field $norm = 2 * pi * $frequency / Audio::Aoede->rate;

    method next_samples ($n_samples,$since=0) {
        $since -= int ($since/$samples_per_period);
        my $phase = (sequence($n_samples) + $since) * $norm;
        my $samples = sin($phase);
        return $samples;
    }
}

use PDL;
use Audio::Aoede::LPCM;
my $lpcm = Audio::Aoede::LPCM->new(
    rate => Audio::Aoede->rate,
    data => short(Audio::Aoede::Voice::Sine->new(frequency =>440)
                  ->next_samples(Audio::Aoede->rate) * 2**14)
    ->get_dataref->$*
    );
$lpcm->write_wav('/tmp/sine.wav');
