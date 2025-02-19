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
field $min_frequency :param;
field $max_frequency :param;
field $plot;
field $max_y = '-Inf';
field %spectra;
field $channels :param;
field $show_halftone_grid = 0;
field $halftones;

ADJUST {
    $plot = $parent->insert(
        Plot =>
        color => cl::Black,
        pack => $pack,
        backColor => cl::White,
        size => $size,
        visible => 0,
    );
    $plot->x->scaling(main::get_config('axis_type'));
    $halftones = (2**(1/12)) ** (sequence(124)-57);
}


my %colors = (
    left => cl::Blue,
    right => cl::Red,
);


my %orientations = (
    left => 1,
    right => -1,
);


method set_min_frequency ($new) {
    return if $new >= $plot->x->max;
    $min_frequency = $new;
    $plot->x->min($min_frequency);
    return;
}


method set_max_frequency ($new) {
    return if $new <= $plot->x->min;
    $max_frequency = $new;
    $plot->x->max($max_frequency);
    return;
}


method set_axis_linear () {
    $plot->x->scaling(sc::Linear);
}


method set_axis_logarithmic () {
    $plot->x->scaling(sc::Log);
}


method show_halftone_grid () {
    $show_halftone_grid = 1;
}


method hide_halftone_grid () {
    $show_halftone_grid = 0;
}


method update (%data) {
    my $n_data = (values %data)[0]->dim(0);
    return unless $n_data;      # no spectrum yet
    my $min_index = int ($min_frequency * $n_data/$max_frequency + 0.999);
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
                     * ($max_frequency-$min_frequency),
                     $spectrum * $orientations{$channel},
                     plotType => ppair::Histogram,
                     color => $colors{$channel} || cl::Black,
                     backColor => $colors{$channel} || cl::Black,
                 );
        if ($show_halftone_grid) {
            my $ht = $halftones->where(($halftones >= $min_frequency/440)  &
                                       ($halftones <= $max_frequency/440));
            my $tuner_lines = $ht * main::get_config('A4_pitch');
            $plot->dataSets->{pitches} =
                ds::Note(
                    pnote::Line(x1 => { raw => $tuner_lines },
                                x2 => { raw => $tuner_lines }),
                );
            $plot->dataSets->{a4} =
                ds::Note(
                    pnote::Text(sprintf("%6.2f",main::get_config('A4_pitch')),
                                x => { raw => main::get_config('A4_pitch') },
                                y => '90%',
                            )
                );
        }
        else {
            delete $plot->dataSets->{pitches};
            delete $plot->dataSets->{a4};
        }
    }

    $plot->repaint;
}


method clear {
    %{$plot->dataSets} = ();
    $plot->visible(0);
}


method show {
    $plot->show;
}

my %diatonics = (
    white => pdl(0,2,3,5,7,8,10),
    black => pdl(1,4,6,9,11),
);

method calculate_halftones {
    my $start = main::get_config('A4_pitch')/32; # safely below our needs
    my $f = $start;
    while ($f < $max_frequency) {
    }
}


1;
