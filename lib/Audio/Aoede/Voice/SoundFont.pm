# ABSTRACT: A voice playing notes from a soundfont
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Voice::SoundFont { # :isa(Audio::Aoede::Voice) {
    field $instrument :param;
    field $soundfont  :param;
    field $note       :param;
    field $rate       :param;
    field $volume     :param = 1;
    field $start;
    field $sound;
    field $loop;
    field $vol_env;
    field $mod_env;

    use PDL;
    use PDL::Func;

    ADJUST {
        my $generator   = $instrument->generator($note);
        my $sample      = $soundfont->sample($generator->sample_id);
        $generator->set_sample($sample);
        ($sound,$loop)  = $generator->resample($note,$rate);
        # Now take care for the sound phases...
        $vol_env        = $generator->vol_env();
        $mod_env        = $generator->mod_env();
    }

    method next_samples ($n_samples,$since) {
        if (! $start) {
            $start = $since;
        }
        my $offset = $since-$start;
        if ($offset + $n_samples <= $sound->dim(0)) {
            my $samples = $sound->slice([$offset,$offset+$n_samples-1]);
            my $filtered_samples = $mod_env->apply($samples,$offset);
            return $filtered_samples
                * $vol_env->slice([$offset,$offset+$n_samples-1])
                * $self->volume;
        }
        else {
            my $n_loops = int(($n_samples - $sound->dim(0)) / $loop->dim(0)) + 1;
            my $samples = $sound->glue(0,($loop) x $n_loops)->slice([0,$n_samples-1]);
            my $filtered_samples = $mod_env->apply($samples,$offset);
            return $filtered_samples
                * $vol_env->slice([$offset,$offset+$n_samples-1])
                * $self->volume;
        }
    }

    method volume () { $volume }
    method set_volume ($new_volume) {
        $volume = $new_volume;
    }

}

1;
