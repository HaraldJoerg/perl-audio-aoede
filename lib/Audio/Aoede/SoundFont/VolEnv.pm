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
    if (my $decay = $self->decay) {
        my $n_samples = int($decay * $self->rate + 0.5);
        my $sequence = (sequence($n_samples) / $n_samples);
        my $attenuation = $self->sustain ** $sequence;
        $self->append_env_samples($attenuation);
    }
    if (my $release = $self->release) {
        my $n_samples = int($release * $self->rate + 0.5);
        my $sequence = (sequence($n_samples) / $n_samples);
        my $attenuation = 1E-5 ** $sequence;
        $self->set_rel_samples($attenuation);
    }
}


method apply ($samples,$first) {
    if (! $self->env_samples->isempty) {
    }
}


1;
