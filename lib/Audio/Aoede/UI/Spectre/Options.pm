# ABSTRACT: Configuration options for Aoede's audio spectrum viewer UI
package Audio::Aoede::UI::Spectre::Options;
use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::Spectre::Options;

use Prima qw( Buttons );
use Audio::Aoede::UI::Spectre::Option;

field $parent                   :param;
field $pack                     :param;
field $options_ui;
field $tun_row;

my @colnames = (qw ( label field unit ) );

ADJUST {
    my $frame = $parent->insert(
        Widget =>
        pack => $pack,
        backColor => cl::Black,
    );
    $options_ui = Prima::Widget->new(
        owner => $frame,
        backColor => cl::White,
        pack => { pad => 2 },
        ownerBackColor => 1,
    );
    my $fps_row = Audio::Aoede::UI::Spectre::Option->new(
        parent => $options_ui,
        label  => 'Frame rate:',
        field  => [
            InputLine =>
            text      => main::get_config('fps'),
            onChange  => sub ($widget) {
                main::set_fps($widget->text);
            },
        ],
        units  => 'FPS',
    );
    $fps_row->set_row(6);

    my $res_row = Audio::Aoede::UI::Spectre::Option->new(
        parent => $options_ui,
        label  => 'Resolution:',
        field  => [
            InputLine =>
            text      => main::get_config('resolution'),
            onChange  => sub ($widget) {
                main::set_resolution($widget->text);
            },
        ],
        units  => 'Hz',
    );
    $res_row->set_row(5);

    my $min_row = Audio::Aoede::UI::Spectre::Option->new(
        parent => $options_ui,
        label  => 'Min frequency:',
        field  => [
            InputLine =>
            text => main::get_config('min_frequency'),
            onChange => sub ($widget) {
                main::set_min_frequency->($widget->text)
            },
        ],
        units  => 'Hz',
    );
    $min_row->set_row(4);

    my $max_row = Audio::Aoede::UI::Spectre::Option->new(
        parent => $options_ui,
        label  => 'Max frequency:',
        field  => [
            InputLine =>
            text => main::get_config('max_frequency'),
            onChange => sub ($widget) {
                main::set_max_frequency->($widget->text)
            },
        ],
        units  => 'Hz',
    );
    $max_row->set_row(3);

    my $axo_field = $options_ui->insert(
        GroupBox =>
        name => ' ',
        border => 0,
    );
    $axo_field->insert(
        Radio =>
        name => 'linear',
        onClick => sub { main::set_axis_linear() },
        pack => { side => 'top', anchor => 'w',},
    );
    $axo_field->insert(
        Radio =>
        name => 'logarithmic',
        checked => 1,
        onClick => sub { main::set_axis_logarithmic() },
        pack => { side => 'top', anchor => 'w'},
    );
    my $axo_row = Audio::Aoede::UI::Spectre::Option->new(
        parent => $options_ui,
        label  => 'Frequency axis:',
        field  => $axo_field,
    );
    $axo_row->set_row(2);

    my $hgr_row = Audio::Aoede::UI::Spectre::Option->new(
        parent => $options_ui,
        label  => 'Show halftone grid',
        field => [
            CheckBox =>
            text => ' ',
            ownerBackColor => 1,
            onClick => sub ($widget) {
                if ($widget->checked) {
                    $tun_row->enable;
                    main::show_halftone_grid();
                }
                else {
                    $tun_row->disable;
                    main::hide_halftone_grid();
                }
                main::run_current_spectrum();
            }
        ],
    );
    $hgr_row->set_row(1);

    $tun_row = Audio::Aoede::UI::Spectre::Option->new(
        parent => $options_ui,
        label  => 'Fine tuning:',
        field  => [
            CircularSlider =>
            buttons => 1,
            increment => 1,
            min => -50,
            max => 50,
            onChange => sub ($widget) {
                my $v = $widget->value;
                main::set_tuner_base(440 * (2**($v/1200)));
            },
        ],
        units  => 'Cent',
    );
    $tun_row->set_row(0);
    $tun_row->disable;
}


method disable_hgr () {
    $tun_row->disable;
}


method enable_hgr () {
    $tun_row->enable;
}

1;
