# ABSTRACT: An Aoede source for a sine wave and its overtones
use 5.032;
package Audio::Aoede::Harmonics 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Harmonics {
    use PDL;
    use Audio::Aoede::Functions qw ( f_sine_wave );
    use Audio::Aoede::Link;
    use Audio::Aoede::Source;

    field $frequency :param;
    field $total_volume :reader(volume) = 1; # that's for the sum of it
    field @volumes = ();
    field $volumes  :param = undef;
    field $rate     :param;
    field $function = f_sine_wave($rate);
    field $link     = Audio::Aoede::Link->new;

    my $max_frequency = 22000;

    ADJUST {
        if ($volumes) {
            @volumes = @$volumes;
            undef $volumes;
        }
        # Normalize the volume by running one full period
        my $samples_per_period = $rate / $frequency;
        my $period = $self->next_samples($samples_per_period,0);
        my $max = $period->abs->max;
        $total_volume = $max > 1 ? 1/$max : 1;
    }


    method set_volumes (@new) {
        @volumes = new;
        return $self;
    }


    method set_link($new_link) {
        $link = $new_link;
        return $self;
    }


    method next_samples ($n_samples,$first) {
        use builtin qw( indexed );
        my $samples = zeroes($n_samples);
      REGISTER_STOP:
        for my ($i,$volume) (indexed @volumes) {
            next REGISTER_STOP unless $volume;
            my $overtone  =  ($i+1) * $frequency;
            last REGISTER_STOP if $overtone > $max_frequency;
            $samples += $volume * $function->($n_samples,$overtone,$first);
        }
        return $total_volume * $samples;
    }
}

1;
