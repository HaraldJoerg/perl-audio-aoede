# ABSTRACT: Aoede information about the "current object"
package Audio::Aoede::File;

use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::File;

use PDL;

field $position :reader = 0;
field $sound;
field @channels;


method set_sound ($new) {
    $sound = $new;
    @channels = $sound->transpose->dog;
}


method sound () {
    $sound = cat(@channels)->transpose;
    return $sound;
}

method n_samples {
    return $channels[0]->dim(0);
}


method set_position ($new) {
    $position = $new;
}


method add_time ($delta) {
    $position += $delta;
}


method channel ($number) {
    return $channels[$number];
}


method append_sound ($sound) {
    my @new = $sound->transpose->dog;
    @channels = map { $_->append(shift(@new)) } @channels;
}
1;
