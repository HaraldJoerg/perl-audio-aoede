# ABSTRACT: Show users that Aoede is busy
package Audio::Aoede::UI::Busy;

use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::Busy;

use Prima;

field $parent :param;
field $text   :param = 'Busy';
field $ui;
field $label;

ADJUST {
    $ui = $parent->insert(
        Widget =>
        borderIcons    => 0,
        borderStyle    => bs::None,
        centered       => 1,
        growMode       => 0,
        on_top         => 1,
        ownerBackColor => 1,
        size           => [200,200],
        taskListed     => 0,
        text           => 'Please wait',
    );
    $label = $ui->insert(
        Label          =>
        ownerBackColor => 1,
        text           => $text,
        pack           => { side => 'top', },
    );
    $ui->insert(
        Spinner        =>
        active         => 1,
        ownerBackColor => 1,
        pack           => { fill => 'both', expand => 1, },
        style          => 'spiral',
    );
    $::application->yield;
}


method destroy {
    $ui->destroy;
    undef $ui;
    $parent->focus;
}


1;
