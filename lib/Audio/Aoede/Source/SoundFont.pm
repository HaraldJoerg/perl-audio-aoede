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
    field $name       :param :reader = q([no name]);
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
    field $lowpass_filter;

    # FIXME: In the current implementation, "$since" is an absolute
    # number since the start of playing stuff.  The first call to
    # next_samples stores this time as $start and calculates $offset
    # as the time we spent in this note.
    method next_samples ($n_samples,$since) {
        if (! $link) {
            $link = Audio::Aoede::Link->new(offset => $since);
            $lowpass_filter = $mod_env->lowpass_filter;
        }
        if ($released) {
            return $self->trailer_samples($n_samples,$since);
        }
        else {
            my $first = $since - $link->offset;
            my $samples;
            if ($first + $n_samples < $sound->dim(0)) {
                # Supply all samples from our source
                $samples   = $sound->slice([$first,$first+$n_samples-1]);
            }
            elsif ($first + $n_samples == $sound->dim(0)) {
                # Supply all samples from our source, check loops
                $exhausted = $loop->isempty;
                $samples   = $sound->slice([$first,$first+$n_samples-1]);
            }
            elsif ($loop->isempty) {
                # Not enough samples in our source, no loops
                $samples = zeroes($n_samples);
                $samples->slice([0,$sound->dim(0)-$first-1]) .=
                    $sound->slice([$first,-1]);
                $exhausted = 1;
            }
            else {
                # Process loops
                my $n_loops = int(($first + $n_samples - $sound->dim(0)) / $loop->dim(0)) + 1;
                $samples = $sound->glue(0,($loop) x $n_loops)->slice([$first,$first + $n_samples-1]);
            }

            # Now apply the envelopes
            if ($lowpass_filter) {
                my $cutoff_data = $mod_env->cutoff_data($first,$n_samples);
                $samples = $lowpass_filter->process($samples,$cutoff_data);
            }
            $samples *= $vol_env->env_samples($first,$n_samples);
            return $samples * $velocity/127;
        }
    }


    method trailer_samples ($n_samples,$since) {
        my $first = $since - $link->offset;
        if ($trailer->dim(0) > $first + $n_samples) {
            return $trailer->slice([$first,$first+$n_samples-1]);
        }
        elsif ($trailer->dim(0) == $first + $n_samples) {
            $exhausted = 1;
            return $trailer->slice([$first,-1]);
        }
        else {
            my $rest = zeroes($n_samples);
            $rest->slice([0,$trailer->dim(0)-$first-1]) .=
                $trailer->slice([$first,-1]);
            $exhausted = 1;
            return $rest;
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
