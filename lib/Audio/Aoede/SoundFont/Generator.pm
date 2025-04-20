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
    use Audio::Aoede::SoundFont::Resample;
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
    field $pan                        :param :reader = 0;  # 17
    field $releaseModEnv              :param = -12000;  # 30
    field $releaseVolEnv              :param = -12000;  # 38
    field $reverbEffectsSend          :param = 0;       # 16
    field $sampleID                   :param;           # 53
    field $sampleModes                :param = 0;       # 54
    field $scaleTuning                :param = 100;     # 56
    field $sustainModEnv              :param = 0;       # 29
    field $sustainVolEnv              :param = 0;       # 37
    field $startAddrsOffset           :param = 0;       #  0
    field $startAddrsCoarseOffset     :param = 0;       #  4
    field $startloopAddrsCoarseOffset :param = 0;       # 45
    field $startloopAddrsOffset       :param = 0;       #  2
    field $vibLfoToPitch              :param = 0;       #  6
    field $velocity                   :param = -1;      # 47
    field $velRange                   :param = [0,127]; # 44

    field $sfSample                   :param;
    field $name               :reader :param = q([no name]);
    field $samples; # the data after applying our filter

    field %mod_env_cache;
    
    use PDL;
    use PDL::Func;

    ADJUST {
        if ($overridingRootKey == -1) {
            undef $overridingRootKey;
        }
        if ($velocity == -1) {
            undef $velocity;
        }
        $samples = double $sfSample->data;
    }


    method vol_env ($note,$rate) {
        return Audio::Aoede::SoundFont::VolEnv->new_from_sf(
            rate             => $rate,
            delayVolEnv      => $delayVolEnv,
            attackVolEnv     => $attackVolEnv,
            holdVolEnv       => $holdVolEnv,
            decayVolEnv      => $decayVolEnv,
            sustainVolEnv    => $sustainVolEnv,
            releaseVolEnv    => $releaseVolEnv,
        );
    }

    method mod_env ($note,$rate) {
        if (my $mod_env = $mod_env_cache{$note}{$rate}) {
            return $mod_env;
        }
        if ($modEnvToPitch) {
            say "Cheating! Set Attack to 0";
            $attackModEnv = 0;
            $sustainModEnv = 0;
            $modEnvToPitch = abs $modEnvToPitch;
        }
        my $mod_env = Audio::Aoede::SoundFont::ModEnv->new_from_sf(
            rate             => $rate,
            delayModEnv      => $delayModEnv,
            attackModEnv     => $attackModEnv,
            holdModEnv       => $holdModEnv,
            decayModEnv      => $decayModEnv,
            sustainModEnv    => $sustainModEnv,
            releaseModEnv    => $releaseModEnv,
            modEnvToPitch    => $modEnvToPitch,
            initialFilterFc  => $initialFilterFc,
            modEnvToFilterFc => $modEnvToFilterFc,
        );
        my $key = $overridingRootKey || $sfSample->by_original_key;
        my $interval = HALFTONE ** ($note - $key) * CENT ** $fineTune;
        $mod_env->adjust_filter_cutoff($interval);
        $mod_env_cache{$note}{$rate} = $mod_env;
        return $mod_env;
    }

    method resample ($note,$rate) {
        die "We have no samples" unless $sfSample;
        my $resampled;
        my $loop = empty;
        
        my $start = $sfSample->start
            + $startAddrsCoarseOffset * 2**15
            + $startAddrsOffset;
        my $end = $sfSample->end
            + $endAddrsCoarseOffset * 2**15
            + $endAddrsOffset;

        my $n_samples = $end - $start;
        my $key = $overridingRootKey || $sfSample->by_original_key;
        my $interval = HALFTONE ** ($note - $key) * CENT ** $fineTune;
        my $xi;
        # if ($sampleModes & 1) { # Sound loops
        #     my $start_loop = $sfSample->start_loop
        #         + $startloopAddrsCoarseOffset * 2**15
        #         + $startloopAddrsOffset;
        #     my $end_loop = $sfSample->end_loop
        #         + $endloopAddrsCoarseOffset * 2**15
        #         + $endloopAddrsOffset;
        # }
        if ($modEnvToPitch) {
            say "$name: Key=$key+$interval: We have modEnvToPitch = $modEnvToPitch";
            my $mod_env = $self->mod_env($note,$rate);
            my $mod_samples = $mod_env->env_samples(0,$end-$start);
            $interval *= CENT ** ($modEnvToPitch * $mod_samples);
            $interval *= $sfSample->rate/$rate;
            $xi = $interval->copy;
            if ($sampleModes & 1) { # Sound loops
                my $start_loop = $sfSample->start_loop
                    + $startloopAddrsCoarseOffset * 2**15
                    + $startloopAddrsOffset;
                my $end_loop = $sfSample->end_loop
                    + $endloopAddrsCoarseOffset * 2**15
                    + $endloopAddrsOffset;
                my $state = pdl(0);
                $resampled = resample_with_loop(
                    $samples->slice([$start,$end-1]),
                    $xi,$state,$start_loop,$end_loop);
            }
        }
        else {
            my $obj = PDL::Func->init( Interpolate => "Linear" );
            $obj->set(x => sequence ($n_samples),
                      y => $samples->slice([$start,$end-1]));
            my $factor = $rate/$sfSample->rate / $interval;
            $xi = sequence($n_samples * $factor) / $factor;
            my $resampled = $obj->interpolate($xi);
            if ($sampleModes & 1) { # Sound loops
                my $start_loop = $sfSample->start_loop
                    + $startloopAddrsCoarseOffset * 2**15
                    + $startloopAddrsOffset;
                my $end_loop = $sfSample->end_loop
                    + $endloopAddrsCoarseOffset * 2**15
                    + $endloopAddrsOffset;
                return ($resampled->slice([$start*$factor,$start_loop*$factor-1]),
                        $resampled->slice([$start_loop*$factor,$end_loop*$factor-1]));
            }
            else {
                return ($resampled->slice([$start*$factor,$end*$factor-1]),
                        empty);
            }
        }
        $resampled *= cB_to_amplitude_factor(-$initialAttenuation);
        return ($resampled,$loop);
    }
}


1;

=head1 NAME

Audio::Aoede::SoundFont::Generator - a SoundFont Generator

=head1 DESCRIPTION

This documentation is horribly incomplete.
