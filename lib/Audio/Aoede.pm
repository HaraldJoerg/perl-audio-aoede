# ABSTRACT: Create and Analyze Sound
package Audio::Aoede 0.01;
use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede {
    use File::Temp;

    use Audio::Aoede::LPCM;
    use Audio::Aoede::Player::WAV;
    use Audio::Aoede::Player::SoX;

    field $rate :param = 44100;
    field $channels = 1;
    field $bits = 16;
    field $samples;
    field @voices;
    field $player :param = Audio::Aoede::Player::WAV->new;

    my $amplitude = 2**15-1;

    ADJUST {
        if ($player eq 'sox') {
            $player = Audio::Aoede::Player::SoX->new(
                rate => $rate,
                bits => $bits,
                channels => $channels
            );
        }
    }

    
    # FIXME: This is still all single channel stuff

=head2 write_wav - write samples as a .wav file

FIXME: Only works with one channel right now.

=cut
    method player {
        return $player;
    }

    method write ($voice) {
        my $samples = $voice->samples;
        my $lpcm = Audio::Aoede::LPCM->new(
            rate     => $rate,
            bits     => $bits,
            encoding => 'signed-integer',
            channels => $channels,
            data     => short($samples * $amplitude)->get_dataref->$*,
        );
        $player->write_lpcm($lpcm);
    }

}

use Exporter 'import';
our @EXPORT_OK = qw( sine_wave );

use PDL;
use Audio::Aoede::Units qw( PI rate );

sub sine_wave () {
    return sub ($frequency, $n_samples, $since = 0) {
        my $samples_per_period = rate() / $frequency;
        my $norm = 2 * PI() / $samples_per_period;
        $since -= int ($since/$samples_per_period);
        my $phase = (sequence($n_samples) + $since) * $norm;
        my $samples = sin($phase);
        return $samples;
    }
}

1;
