use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Player {
    field $handle;

    method handle {
        return $handle;
    }

    method _set_handle ($new_handle) {
        $handle = $new_handle;
    }

}

1;
