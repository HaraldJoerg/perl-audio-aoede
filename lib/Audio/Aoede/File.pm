# ABSTRACT: Aoede information about the "current object"
package Audio::Aoede::File;

use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::File;

use PDL;
use File::Spec;

field $handle   :reader;
field $path     :param  = undef;
field $position :reader = 0;
field $duration :reader = 0;
field $bits     = 16;
field $channels = 2;
field $rate     = 48000;
field $raw_data;
field $sound;
field @channels;


# Alternate constructor
# When reading from a file via SoX, we can just set the parameters.
# For now, we're using the field defaults... which could as well be
# class defaults.
sub pipe_from_file ($class,$path) {
    require Audio::Aoede::Recorder::SoX;
    my $self = $class->new(
        path => $path,
    );
    $self->open_pipe();
    return $self;
}


method open_pipe () {
    my $reader = Audio::Aoede::Recorder::SoX->new(
        rate     => $rate,
        bits     => $bits,
        channels => $channels,
    );
    $handle = $reader->open_pipe($path);
}


method read_pipe ($n_samples) {
    my $n_bytes = $n_samples * $channels * $bits/8;
    my $data;
    my $got = sysread $handle,$data,$n_bytes,0;
    if (! $got) {
        # FIXME This could be end of file, or an error.
        # We might to want to distinguish between those.
        return undef;
    }
    $raw_data .= $data;
    return $data;
}



method set_handle ($new) {
    $handle = $new;
}


# This happens after a "save as..." action
method set_path ($new) {
    $path = $new;
}


method file_name () {
    my ($vol,$dirs,$file) = File::Spec->splitpath($path);
    return $file;
}


# FIXME: Eventually we want to go directly from raw data to @channels
method set_data ($data) {
    $raw_data = $data;
}


method append_data ($data) {
    $raw_data .= $data;
}


method set_sound ($new) {
    $sound = $new;
    @channels = $sound->transpose->dog;
}


method sound () {
    return $sound;
}


method update_sound () {
    $sound = cat(@channels)->transpose;
}

method n_samples {
    return scalar @channels ? $channels[0]->dim(0) : 0;
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


method append_sound ($batch) {
    my @new = $batch->transpose->dog;
    @channels = map { $_->append(shift(@new)) } @channels;
}
1;
