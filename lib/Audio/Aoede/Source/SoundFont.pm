# ABSTRACT: A source playing notes from a soundfont
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Source::SoundFont {
    use PDL;
    use PDL::Func;
    use Audio::Aoede::Link;

    field $note       :param;
    field $rate       :param;
    field $velocity   :param = 96;
    field $sound      :param;
    field $loop       :param;
    field $vol_env    :param;
    field $mod_env    :param;
    field $pan        :param :reader;
    field $trailer = empty;

    field $link;
    field $released = 0;
    field $exhausted :reader = 0;

    # FIXME: In the current implementation, "$since" is an absolute
    # number since the start of playing stuff.  The first call to
    # next_samples stores this time as $start and calculates $offset
    # as the time we spent in this note.
    # AA::Source obtains its offset from a AA::Link as the start time.
    # Confusion alert!  We should use the same terminology and
    # implementation for both types of source.
    method next_samples ($n_samples,$since) {
        if (! $link) {
            $link = Audio::Aoede::Link->new(offset => $since);
        }
        my $first = $since - $link->offset;
        my $samples;
        if ($released) {
            if ($trailer->dim(0) > $first + $n_samples) {
                return $trailer->slice([$first,$first+$n_samples-1]);
            }
            elsif ($trailer->dim(0) == $first + $n_samples) {
                $exhausted = 1;
                return $trailer->slice([$first,-1]);
            }
            else {
                my $rest = zeroes($n_samples);
                $rest->slice([0,$trailer->dim(0)-$first-1]) =
                    $trailer->slice([$first,-1]);
                $exhausted = 1;
                return $rest;
            }
        }
        else {
            if ($first + $n_samples < $sound->dim(0)) {
                $samples = $sound->slice([$first,$first+$n_samples-1]);
            }
            elsif ($first + $n_samples == $sound->dim(0)) {
                if ($loop->isempty) {
                    $exhausted = 1;
                }
                $samples = $sound->slice([$first,$first+$n_samples-1]);
            }
            elsif ($loop->isempty) {
                $samples = zeroes($n_samples);
                $samples->slice([0,$sound->dim(0)-$first-1]) =
                    $sound->slice([$first,-1]);
                $exhausted = 1;
            }
            else {
                my $n_loops = int(($first + $n_samples - $sound->dim(0)) / $loop->dim(0)) + 1;
                $samples = $sound->glue(0,($loop) x $n_loops)->slice([$first,$first + $n_samples-1]);
            }
            my $filtered_samples = $mod_env->apply($samples,$first);
            # FIXME:  This is still unused
            my $attenuated_samples = $vol_env->apply($filtered_samples,$first);
            my $vol_env_samples = $vol_env->env_samples;
            if (! $vol_env_samples->isempty) {
                if ($vol_env_samples->dim(0) >= $first+$n_samples ) {
                    $filtered_samples *= $vol_env_samples->slice([$first,$first+$n_samples-1]);
                } else {
                    my $attenuation = ones($first+$n_samples) * $vol_env->sustain;
                    $attenuation->slice([0,$vol_env_samples->dim(0)]) = $vol_env_samples;
                }
            }
            return $filtered_samples * $velocity/127;
        }
    }


    method released ($new_offset) {
        $trailer = $vol_env->trailer_samples($new_offset - $link->offset);
        $trailer *= $self->next_samples($trailer->dim(0),$new_offset);
        $released = 1;
        $link->set_offset($new_offset);
    }
}



1;
