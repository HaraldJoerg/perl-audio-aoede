# Abstract: A Soundfont modulation envelope
package Audio::Aoede::SoundFont::ModEnv;


use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont::ModEnv
    :isa(Audio::Aoede::Envelope::DAHDSR);

use PDL;
use PDL::Filter::Biquad;

use Audio::Aoede::Units qw( CENT MIDI_0 );

use constant max_initialFilterFc => 13500;
use constant no_filter_cutoff => MIDI_0 * CENT ** max_initialFilterFc;

field $modEnvToPitch    :param = 0;
field $initialFilterFc  :param = max_initialFilterFc;
field $modEnvToFilterFc :param = 0;
field $initial_cutoff = MIDI_0 * CENT ** $initialFilterFc;
field $actual_cutoff  = $initial_cutoff;

ADJUST {
    if (my $decay = $self->decay) {
        my $n_samples = int($decay * $self->rate + 0.5);
        my $range = 1 - $self->sustain;
        my $attenuation = sequence($n_samples+1) / $n_samples;
        $self->append_env_samples(1 - $range * $attenuation);
    }
    if (my $release = $self->release) {
        my $n_samples = int($release * $self->rate + 0.5);
        my $attenuation = 1 - sequence($n_samples+1) / $n_samples;
        $self->set_rel_samples($attenuation);
    }
    if ($initialFilterFc >= max_initialFilterFc) {
        undef $actual_cutoff;
    }
}


method adjust_filter_cutoff ($interval) {
    $actual_cutoff = $initial_cutoff * $interval;
    if ($actual_cutoff >= no_filter_cutoff) {
        undef $actual_cutoff;
    }
}


method lowpass_filter () {
    return $modEnvToFilterFc
        ? PDL::Filter::Biquad->new(samplerate => $self->rate)
        : undef;
}


method cutoff_data ($first,$n_samples) {
    return $modEnvToFilterFc
        ? $actual_cutoff
            * CENT ** ($self->env_samples($first,$n_samples)*$modEnvToFilterFc)
        : $actual_cutoff;
}


method modulate_pitch ($samples,$first,$n_samples) {
}

1;
