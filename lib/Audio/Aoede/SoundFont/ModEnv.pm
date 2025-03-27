# Abstract: A Soundfont modulation envelope
package Audio::Aoede::SoundFont::ModEnv;


use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont::ModEnv
    :isa(Audio::Aoede::Envelope::DAHDSR);

use PDL;

use Audio::Aoede::Units qw( CENT MIDI_0 );

field $initialFilterFc  :param = 13500;
field $modEnvToFilterFc :param = 0;
field $initial_cutoff = MIDI_0 * CENT ** $initialFilterFc;;
field $actual_cutoff;


ADJUST {
    if ($self->decay) {
        my $n_samples = int($self->decay * $self->rate + 0.5);
        my $range = 1 - $self->sustain;
        my $attenuation = sequence($n_samples+1) / $n_samples;
        $self->append_env_samples(1 - $range * $attenuation);
    }
}


method adjust_filter_cutoff ($interval) {
    $actual_cutoff = $initial_cutoff * $interval;
}

method apply($samples,$offset) {
    if ($self->env_samples->isempty) {
        return $samples;
    }
    require Audio::Aoede::Filter::Biquad;
    my $filter = Audio::Aoede::Filter::Biquad->new(
        samplerate => $self->rate,
        cutoff     => $actual_cutoff,
    );
    my @filtered;
    for my ($index,$sample) (builtin::indexed $samples->list) {
        my $filtered = $filter->process_sample($sample);
        push @filtered,$filtered;
        my $effective_cutoff = $actual_cutoff * CENT ** ($modEnvToFilterFc * $self->env_samples->at($index));
        $filter->set_cutoff($effective_cutoff);
    }
#    @filtered = map { $filter->process_sample($_) } $samples->list;
    return pdl(@filtered);
}

