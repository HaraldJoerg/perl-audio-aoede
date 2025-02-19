package Audio::Aoede::UI::Spectrogram;
use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::Spectrogram;

use PDL;
use PDL::Graphics::Prima;
use PDL::DSP::Windows;
use Prima;

field $parent :param;
field $spectrogram_window;
field $plot;
field $time :param;
field $size = [600,600];
field $min_frequency :param;
field $max_frequency :param;


ADJUST {
    no warnings "once";
    $spectrogram_window = $parent->insert(
        Window =>
        text => "$::title Spectrogram",
        onClose => sub { undef $spectrogram_window },
        size => $size,
    );
}


method set_time ($new) {
    if ($new > 0) {
        $time = $new;
    }
}


method set_min_frequency ($new) {
    if ($new > 0) {
        $min_frequency = $new;
    }
}


method set_max_frequency ($new) {
    if ($new > 0) {
        $max_frequency = $new;
    }
}


method show_spectrogram ($spectrogram) {
    $plot = $spectrogram_window->insert(
        Plot =>
        -spectrogram=> ds::Grid(
                $spectrogram,
                x_bounds => [0,$time],
                y_bounds => [$min_frequency,$max_frequency],
                plotType => pgrid::Matrix(palette => pal::WhiteToBlack),
            ),
        y => { scaling => sc::Log },
        pack => { side => 'top', expand => 1, fill => 'both' },
    );
}


method update_spectrogram ($spectrogram) {
    if (defined $spectrogram_window) {
        $plot->dataSets->{spectrogram} = ds::Grid(
            $spectrogram,
            x_bounds => [0,$time],
            y_bounds => [$min_frequency,$max_frequency],
            plotType => pgrid::Matrix(palette => pal::WhiteToBlack),
        ),
    }
    else {
        $spectrogram_window = $parent->insert(
            Window =>
            onClose => sub { undef $spectrogram_window },
            size => $size,
        );
        $self->show_spectrogram($spectrogram);
    }
}

1;
