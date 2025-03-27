# ABSTRACT: An object representing a .sf2 SoundFont sample
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont::Sample {
    field $achSampleName :param;
    field $byOriginalKey :param = undef;
    field $chCorrection  :param = undef;
    field $dwStart       :param;
    field $dwEnd         :param;
    field $dwStartloop   :param;
    field $dwEndloop     :param;
    field $dwSampleRate  :param;
    field $sfSampleType  :param;
    field $wSampleLink   :param;
    field $sampledata    :param;
    field $samples;
    field $loop          :reader;

    use PDL 2.099;

    ADJUST {
        # Caveat: We only do 16 bit samples
        my $n_samples   = $dwEnd - $dwStart;
        $samples        = short zeroes ($n_samples);
        my $raw = substr $sampledata,2*$dwStart,2*$n_samples;
        $samples->update_data_from($raw);
        my $l_samples   = $dwEndloop - $dwStartloop;
        $loop           = short zeroes ($l_samples);
        $raw = substr $sampledata,2*$dwStartloop,2*$l_samples;
        $loop->update_data_from($raw);
    }

    method start           { $dwStart }
    method end             { $dwEnd }
    method start_loop      { $dwStartloop }
    method end_loop        { $dwEndloop }

    method by_original_key { $byOriginalKey }
    method rate            { $dwSampleRate }
    {
        no warnings 'redefine';
        method type            { $sfSampleType } # conflicts with PDL
    }
    method data            { $samples }
}

1;
