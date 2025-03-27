# ABSTRACT: An object representing a .sf2 SoundFont generator
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont::Generator {
    use Audio::Aoede::Units qw( CENT
                                HALFTONE
                                MIDI_0
                                cB_to_amplitude_factor
                                seconds_per_timecent );
    use Audio::Aoede::Envelope::DAHDSR;
    use Audio::Aoede::SoundFont::ModEnv;
    use Audio::Aoede::SoundFont::VolEnv;
    # The fields are ordered alphabetically here.
    # Comments indicate the number given to the parameter
    # in the SoundFont Technical Specification, section 8.1.2.
    # There are about sixty of them, many of them optional.
    field $attackModEnv               :param = -12000;  # 26
    field $attackVolEnv               :param = -12000;  # 34
    field $chorusEffectsSend          :param = 0;       # 15
    field $coarseTune                 :param = 0;       # 51
    field $decayModEnv                :param = -12000;  # 28
    field $decayVolEnv                :param = -12000;  # 36
    field $delayModEnv                :param = -12000;  # 25
    field $delayModLFO                :param = -12000;  # 21
    field $delayVibLFO                :param = -12000;  # 23
    field $delayVolEnv                :param = -12000;  # 33
    field $endAddrsOffset             :param = 0;       #  1
    field $endAddrsCoarseOffset       :param = 0;       # 12
    field $endloopAddrsCoarseOffset   :param = 0;       # 50
    field $endloopAddrsOffset         :param = 0;       #  3
    field $endOper                    :param = undef;   # 60
    field $exclusiveClass             :param = 0;       # 57
    field $fineTune                   :param = 0;       # 52
    field $freqModLFO                 :param = 0;       # 22
    field $freqVibLFO                 :param = 0;       # 24
    field $holdVolEnv                 :param = -12000;  # 35
    field $holdModEnv                 :param = -12000;  # 27
    field $initialAttenuation         :param = 0;       # 48
    field $initialFilterFc            :param = 13500;   #  8
    field $initialFilterQ             :param = 0;       #  9
    field $instrument                 :param = undef;   # 41
    field $keynum                     :param = -1;      # 46
    field $keynumToModEnvDecay        :param = 0;       # 32
    field $keynumToModEnvHold         :param = 0;       # 31
    field $keynumToVolEnvDecay        :param = 0;       # 40
    field $keynumToVolEnvHold         :param = 0;       # 39
    field $keyRange                   :param = [0,127]; # 43
    field $modEnvToFilterFc           :param = 0;       # 11
    field $modEnvToPitch              :param = 0;       #  7
    field $modLfoToFilterFc           :param = 0;       # 10
    field $modLfoToPitch              :param = 0;       #  5
    field $modLfoToVolume             :param = 0;       # 13
    field $overridingRootKey          :param = -1;      # 58
    field $pan                        :param = 0;       # 17
    field $releaseModEnv              :param = -12000;  # 30
    field $releaseVolEnv              :param = -12000;  # 38
    field $reverbEffectsSend          :param = 0;       # 16
    field $sampleID                   :param = undef;   # 53
    field $sampleModes                :param = 0;       # 54
    field $scaleTuning                :param = 100;     # 56
    # According to the spec, the defaults of sustainXxxEnv is 0 (zero
    # attenuation or full level), but this does not work for the
    # FluidSynth soundfont patch "Celesta".  Eventually I need to
    # check whether instruments with a nonzero sustain value like a
    # church organ rely on a default of 0.
    field $sustainModEnv              :param = 1000;    # 29
    field $sustainVolEnv              :param = 1000;    # 37
    field $startAddrsOffset           :param = 0;       #  0
    field $startAddrsCoarseOffset     :param = 0;       #  4
    field $startloopAddrsCoarseOffset :param = 0;       # 45
    field $startloopAddrsOffset       :param = 0;       #  2
    field $vibLfoToPitch              :param = 0;       #  6
    field $velocity                   :param = -1;      # 47
    field $velRange                   :param = [0,127]; # 44

    field $sample;  # :writer below - that's AA::Soundfont::Sample
    field $samples; # the data after applying our filter
    field $vol_env;
    field $mod_env;
    use PDL;
    use PDL::Func;

    ADJUST {
        if ($overridingRootKey == -1) {
            undef $overridingRootKey;
        }
        if ($velocity == -1) {
            undef $velocity;
        }
    }


    method set_sample ($new_sample) {
        return if defined $samples; # we've done that already
        return unless defined $new_sample;
        $sample = $new_sample;
        $samples = double $sample->data;
        my $rate = $sample->rate;
        $mod_env = Audio::Aoede::SoundFont::ModEnv->new_from_sf(
            rate             => $rate,
            delayModEnv      => $delayModEnv,
            attackModEnv     => $attackModEnv,
            holdModEnv       => $holdModEnv,
            decayModEnv      => $decayModEnv,
            sustainModEnv    => $sustainModEnv,
            releaseModEnv    => $releaseModEnv,
            initialFilterFc  => $initialFilterFc,
            modEnvToFilterFc => $modEnvToFilterFc,
        );
        $vol_env = Audio::Aoede::SoundFont::VolEnv->new_from_sf(
            rate             => $rate,
            delayVolEnv      => $delayVolEnv,
            attackVolEnv     => $attackVolEnv,
            holdVolEnv       => $holdVolEnv,
            decayVolEnv      => $decayVolEnv,
            sustainVolEnv    => $sustainVolEnv,
            releaseVolEnv    => $releaseVolEnv,
        );
    }


    method vol_env () {
        return $vol_env->env_samples;
    }

    method mod_env () {
        return $mod_env;
    }

    method resample ($note,$rate) {
        return unless $sample;
        my $key = $overridingRootKey || $sample->by_original_key;
        my $interval = HALFTONE ** ($note - $key) * CENT ** $fineTune;
        $mod_env->adjust_filter_cutoff($interval);
        my $start = $sample->start
            + $startAddrsCoarseOffset * 2**15
            + $startAddrsOffset;
        my $end = $sample->end
            + $endAddrsCoarseOffset * 2**15
            + $endAddrsOffset;
        my $start_loop = $sample->start_loop
            + $startloopAddrsCoarseOffset * 2**15
            + $startloopAddrsOffset;
        my $end_loop = $sample->end_loop
            + $endloopAddrsCoarseOffset * 2**15
            + $endloopAddrsOffset;

        my $n_samples = $end - $start;
        my $obj = PDL::Func->init( Interpolate => "Linear" );
        $obj->set(x => sequence ($n_samples),
                  y => $samples->slice([$start,$end-1]));
        my $factor = $rate/$sample->rate / $interval;
        my $xi = sequence($n_samples * $factor) / $factor;
        my $resampled = $obj->interpolate($xi);
        $resampled *= cB_to_amplitude_factor(-$initialAttenuation);
        return ($resampled->slice([$start*$factor,$start_loop*$factor-1]),
                $resampled->slice([$start_loop*$factor,$end_loop*$factor-1]));
    }

    # AA::Voice::SoundFont calls this
    method sample_id {
        return $sampleID;
    }
}


1;

=head1 NAME

Audio::Aoede::SoundFont::Generator - a SoundFont Generator

=head1 DESCRIPTION

This documentation is horribly incomplete.
