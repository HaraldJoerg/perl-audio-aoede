package Audio::Aoede::UI::Spectrum;
use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::Spectrum;

use Prima qw( );
use PDL;
use PDL::Graphics::Prima;

field $parent :param;
field $size :param = [400,400];
field $pack :param;
field $f_min :param;
field $limit :param;
field $plot;
field $max_y = '-Inf';
field %spectra;
field $channels :param;
field $frequency_axis_type :param = sc::Linear;

ADJUST {
    $plot = $parent->insert(
        Plot =>
        color => cl::Black,
        pack => $pack,
        ownerBackColor => 1,
        size => $size,
    );
    $plot->x->scaling($frequency_axis_type);
}


my %colors = (
    left => cl::Blue,
    right => cl::Red,
);


my %orientations = (
    left => 1,
    right => -1,
);


method set_frequency_min ($new) {
    return if $new >= $plot->x->max;
    $f_min = $new;
    $plot->x->min($f_min);
    return;
}


method set_limit ($new) {
    return if $new <= $plot->x->min;
    $limit = $new;
    $plot->x->max($limit);
    return;
}


method set_axis_linear () {
    $frequency_axis_type = sc::Linear;
    $plot->x->scaling(sc::Linear);
}


method set_axis_logarithmic () {
    $frequency_axis_type = sc::Log;
    $plot->x->scaling(sc::Log);
}


method update (%data) {
    # Cut small frequencies in logarithmic scaling
    my $n_data = (values %data)[0]->dim(0);
    return unless $n_data;      # no spectrum yet
    my $min_frequency = $f_min;
    my $min_index = int ($min_frequency * $n_data/$limit + 0.999);
    $n_data -= ($min_index);
    for my ($name,$spectrum) (%data) {
        $data{$name} = $spectrum->slice([$min_index,-1]);
    }
    my $max = '-Inf';
    for my $spectrum (values %data) {
        my $new_max = max($spectrum);
        if ($new_max > $max) {
            $max = $new_max;
        }
    }

    if ($max > $max_y) {
        $max_y = $max;
    }
    elsif ($max < $max_y/2 ) {
        $max_y *= 0.99;
    }
    $plot->y->max($max_y);
    $plot->y->min(-$max_y);
    my $orientation = 1;
    my $line_width = int ($plot->width / $n_data + 0.9);
    for my ($channel,$spectrum) (%data) {
        $orientation = - $orientation;
        $plot->dataSets->{$channel}  =
            ds::Pair(((sequence($n_data)+$min_index) / $n_data)
                     * ($limit-$min_frequency),
                     $spectrum * $orientations{$channel},
                     plotType => ppair::Histogram,
                     color => $colors{$channel} || cl::Black,
                     backColor => $colors{$channel} || cl::Black,
             );
    }

    $plot->repaint;
}


method clear {
    %{$plot->dataSets} = ();
    $plot->repaint;
}


1;
