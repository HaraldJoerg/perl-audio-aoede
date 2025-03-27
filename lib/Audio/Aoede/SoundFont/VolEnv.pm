# Abstract: A Soundfont volume envelope
package Audio::Aoede::SoundFont::VolEnv;


use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont::VolEnv
    :isa(Audio::Aoede::Envelope::DAHDSR);

use PDL;

ADJUST {
    if ($self->decay) {
        my $n_samples = int($self->decay * $self->rate + 0.5);
        my $sequence = (sequence($n_samples) / $n_samples);
        my $attenuation = $self->sustain ** $sequence;
        $self->append_env_samples($attenuation);
    }
}

1;
