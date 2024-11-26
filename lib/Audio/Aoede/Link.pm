# ABSTRACT: A link between Aoede nodes
use 5.032;
package Audio::Aoede::Link 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Link {
    field $offset :param :reader = 0;
    field $next          :reader = $offset;


    method set_offset ($new) {
        $offset = $new;
        return $self;
    }

    method done ($n_samples) {
        $next += $n_samples;
    }


    method done_to ($new_next) {
        $next = $new_next;
    }
}

1;
