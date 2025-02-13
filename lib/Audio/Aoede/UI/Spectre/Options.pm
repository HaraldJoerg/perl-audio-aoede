# ABSTRACT: Configuration options for Aoede's audio spectrum viewer
package Audio::Aoede::UI::Spectre::Options;
use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::Spectre::Options;

field $options_ui;
field $parent                   :param;
field $fps                      :param;
field $fps_callback             :param;
field $resolution               :param;
field $resolution_callback      :param;
field $frequency_limit          :param;
field $frequency_limit_callback :param;
field $frequency_min            :param;
field $frequency_min_callback   :param;

ADJUST {
    $options_ui = Prima::Widget->new(
        pack => { side => 'top' },
        owner => $parent,
        ownerBackColor => 1,
    );
    my $fps_ui = $options_ui->insert(
        Widget =>
        ownerBackColor => 1,
        pack => { side => 'top' },
    );
    $fps_ui->insert(
        Label =>
        text => 'Frame rate: ',
        size => [200,30],
        ownerBackColor => 1,
        pack => { side => 'left' },
    );
    $fps_ui->insert(
        InputLine =>
        text => $fps,
        onChange => sub ($widget) {
            $fps_callback->($widget->text)
        },
        ownerBackColor => 1,
        pack => { side => 'right' },
    );
    my $res_ui = $options_ui->insert(
        Widget =>
        ownerBackColor => 1,
        pack => { side => 'top' },
    );
    $res_ui->insert(
        Label =>
        text => 'Resolution (Hz): ',
        size => [200,30],
        ownerBackColor => 1,
        pack => { side => 'left' },
    );
    $res_ui->insert(
        InputLine =>
        text => $resolution,
        onChange => sub ($widget) {
            $resolution_callback->($widget->text)
        },
        ownerBackColor => 1,
        pack => { side => 'right' },
    );
    my $min_ui = $options_ui->insert(
        Widget =>
        ownerBackColor => 1,
        pack => { side => 'top' },
    );
    $min_ui->insert(
        Label =>
        text => 'Min frequency (Hz): ',
        size => [200,30],
        ownerBackColor => 1,
        pack => { side => 'left' },
    );
    $min_ui->insert(
        InputLine =>
        text => $frequency_min,
        onChange => sub ($widget) {
            $frequency_min_callback->($widget->text)
        },
        ownerBackColor => 1,
        pack => { side => 'right' },
    );
    my $lim_ui = $options_ui->insert(
        Widget =>
        ownerBackColor => 1,
        pack => { side => 'top' },
    );
    $lim_ui->insert(
        Label =>
        text => 'Max frequency (Hz):',
        size => [200,30],
        ownerBackColor => 1,
        pack => { side => 'left' },
    );
    $lim_ui->insert(
        InputLine =>
        text => $frequency_limit,
        onChange => sub ($widget) {
            $frequency_limit_callback->($widget->text)
        },
        ownerBackColor => 1,
        pack => { side => 'right' },
    );
}



1;
