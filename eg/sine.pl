use 5.032;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

use PDL;
use constant pi => atan2(0,-1); # Math::Trig collides with PDL

use Audio::Aoede;

sub sine_wave ($frequency) {
    my $samples_per_period = Audio::Aoede->rate / $frequency;
    my $norm = 2 * pi / $samples_per_period;
    return sub ($n_samples, $since = 0) {
        $since -= int ($since/$samples_per_period);
        my $phase = (sequence($n_samples) + $since) * $norm;
        my $samples = sin($phase);
        return $samples;
    }
}

use PDL;
use Audio::Aoede::LPCM;
my $wave = sine_wave(440);
my $samples = $wave->(Audio::Aoede->rate);
my $lpcm = Audio::Aoede::LPCM->new(
    rate => Audio::Aoede->rate,
    data => short($samples * 2**14)->get_dataref->$*,
    );
$lpcm->write_wav('/tmp/sine.wav');
