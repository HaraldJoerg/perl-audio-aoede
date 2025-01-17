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
field $limit :param;
field $plot;
field $max_y = '-Inf';
field %spectra;
field $channels :param;

ADJUST {
    $plot = $parent->insert(
        Plot =>
        color => cl::Black,
        backColor => cl::White,
        pack => $pack,
        y => { min => 0,
               max => 1,
           },
        size => $size,
    )
}

my %colors = (
    left => cl::Blue,
    right => cl::Red,
);

my %orientations = (
    left => 1,
    right => -1,
);


method set_limit ($new) {
    $limit = $new;
    $plot->x->max($limit);
    return;
}


method update (%data) {
    my $n_samples = (values %data)[0]->dim(0);
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
    elsif ($max < $max_y/4 ) {
        $max_y *= 0.99;
    }
    $plot->y->max($max_y);
    $plot->y->min(-$max_y);
    my $orientation = 1;
    my $line_width = int ($plot->width / $n_samples + 0.9);
    for my ($channel,$spectrum) (%data) {
        $orientation = - $orientation;
        $plot->dataSets->{$channel}  =
            ds::Pair((sequence($n_samples) / $n_samples) * $limit,
                     $spectrum * $orientations{$channel},
                     # plotType => ppair::Spikes(lineWidths => $line_width),
                     plotType => ppair::Lines,
                     color => $colors{$channel} || cl::Black,
             );
    }

    $plot->repaint;
}


method clear {
    %{$plot->dataSets} = ();
    $plot->repaint;
}


1;
