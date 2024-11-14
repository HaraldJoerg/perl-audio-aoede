# ABSTRACT: An Aoede source for a sine wave and its overtones
use 5.032;
package Audio::Aoede::Harmonics 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Harmonics {
    use Audio::Aoede::Functions qw ( :waves );
    field $frequency :param;
    field @volumes = ();
    field $volumes  :param = undef;
    field $rate     :param;


    ADJUST {
        if ($volumes) {
            @volumes = @$volumes;
            undef $volumes;
        }
    }


    method set_volumes (@new) {
        @volumes = new;
        return $self;
    }


    method next_samples ($n_samples,$first) {
    }
}
