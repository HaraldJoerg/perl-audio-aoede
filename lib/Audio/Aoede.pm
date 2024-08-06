# ABSTRACT: Create and Analyze Sound
package Audio::Aoede 0.01;
use 5.032;
use feature 'signatures';
no warnings 'experimental';

use Exporter 'import';
our @EXPORT_OK = qw( sine_wave );

our $rate = 44100;
use PDL;
use constant pi => atan2(0,-1); # Math::Trig collides with PDL

sub rate { return $rate }

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

sub write_wav ($samples) {
    use Audio::Aoede::LPCM;
    my $lpcm = Audio::Aoede::LPCM->new(
        rate => $rate,
        data => short($samples * 2**14)->get_dataref->$*,
    );
    $lpcm->write_wav('/tmp/sine.wav');
}

1;
