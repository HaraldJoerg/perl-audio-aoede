package Audio::Aoede::Tremolo;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Tremolo;

field $width     :param :reader = 0;
field $frequency :param :reader = undef;

ADJUST {
    if ($width  &&  !$frequency) {
        croak("Error:  A nonzero width needs a nonzero frequency.\n" .
              "width = '$width', frequency = " . ($frequency // '[undef]'));
    }
}

1;
