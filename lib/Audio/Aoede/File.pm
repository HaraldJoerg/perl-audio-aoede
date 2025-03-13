# ABSTRACT: Aoede information about the "current object"
package Audio::Aoede::File;

use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::File;

use PDL;
use File::Spec;

field $path     :param;
field $position :reader = 0;
field $duration :reader = 0;
field $rate;
field $sound;
field @channels;


# This happens after a "save as..." action
method set_path ($new) {
    $path = new;
}


method file_name () {
    my ($vol,$dirs,$file) = File::Spec->splitpath($path);
    return $file;
}


method set_sound ($new) {
    $sound = $new;
    @channels = $sound->transpose->dog;
}


method sound () {
    return $sound;
}


method n_samples {
    return $channels[0]->dim(0);
}


method set_duration ($new) {
    $duration = $new;
}


method set_position ($new) {
    $position = $new;
}


method increment_position ($by) {
    $position += $by;
    return $position;
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
