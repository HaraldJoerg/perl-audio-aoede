# ABSTRACT: One track of an Aoede opus
package Audio::Aoede::Track;
use 5.036;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Track;

use constant PI => atan2(0,-1);

field @notes;
field $timbre :param :reader = undef;

field $effects :param = [];


method notes {
    return @notes;
}


method set_timbre ($new) {
    $timbre = $new;
    return $self;
}

method add_notes (@new) {
    push @notes,@new;
    return $self;
}
1;
