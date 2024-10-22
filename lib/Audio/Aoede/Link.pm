# ABSTRACT: A link between Aoede nodes
use 5.032;
package Audio::Aoede::Link 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Link {
    field $offset :param = 0;
    field $next          = $offset;


    method next {
        return $next;
    }


    method set_next ($new) {
        $next = $new;
    }


    method done ($n_samples) {
        $next += $n_samples;
    }


    method offset {
        return $offset;
    }
}

1;
