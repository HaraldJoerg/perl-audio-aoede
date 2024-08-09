# ABSTRACT: One voice in the Aoede Orchestra
use 5.032;
package Audio::Aoede::Voice 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Voice {
    use PDL;

    use Audio::Aoede::Units qw( named_note2frequency
                          );

    field $function :param;
    field $samples = pdl([]);

    method add_named_note($note) {
        my ($frequency,$n_samples) = named_note2frequency($note);
        if ($frequency) {
            $samples = $samples->append($function->($frequency,$n_samples));
        }
        else {
            $samples = $samples->append(zeroes($n_samples));
        }
    }

    method samples() {
        return $samples;
    }
}

1;
