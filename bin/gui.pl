use 5.032;
use strict;
use feature "signatures";
no warnings "experimental";

use Prima;
use Prima::Application name => 'Sound from Scratch';
use PDL::Graphics::Prima;
use Scalar::Util qw( refaddr );
use FindBin;
use lib "$FindBin::Bin/../lib";

use Audio::Aoede::Server;
use Audio::Aoede::UI::Oscilloscope;
use Audio::Aoede::UI::Register;
use Audio::Aoede::UI::Tuner;
use Audio::Aoede::Units qw( symbol );

######################################################################
# Configuration hardwired right now
my $tick = 1/50;  # in synch with my graphics card
my $rate = 48000; # e have 800 samples per second
my %timer_objects;


my $server = Audio::Aoede::Server->new(
    rate => $rate,
);

my $main = Prima::MainWindow->create(
    text  => 'Sound from Scratch',
    backColor => cl::White,
    # Prima::Menu has a description of these formats
    menuItems =>
    [
        ['~File' =>
         [
            ['~Quit' => 'Ctrl+Q', '^Q',
             sub { $::application->close } ],
        ],
     ],
        ['~View' =>
         [
             ['@', # Empty Identifier with "auto-toggle" indicator
              '~Oscilloscope', # What's shown with keyboard shortcut
              #  We'll use that for "open file" later, so just for testing
              'Ctrl-O',        # Accelerator text
              '^O',            # The actual hotkey representation
              sub { toggle_oscilloscope() },
          ]
         ]
     ]
    ],
);

my $controls_widget = $main->insert(
    Widget =>
    pack => { side => 'top', fill => 'both' },
);

my $timer = $::application->insert(
    Timer =>
    timeout => 1000 * $tick,
    onTick  => sub { tick() }
);


my ($power,$play);
$power = $controls_widget->insert(
    Button =>
    checkable => 1,
    text => symbol("POWER"),
    onClick => sub ($widget) {
        if ($widget->checked) {
            $widget->backColor(cl::LightRed);
            $play->enabled(1);
            $server->start;
            register_timer($server);
        }
        else {
            $widget->backColor(cl::White);
            $play->checked(0);
            $play->enabled(0);
            $play->text(symbol("PLAY"));
            $play->backColor(cl::White);
            unregister_timer($server);
            $server->stop;
        }
    },
    pack => { side => 'left', fill => 'both' },
);
my $register = Audio::Aoede::UI::Register->new();
$register->insert_to($main);

my $tuner = Audio::Aoede::UI::Tuner->new();
$tuner->insert_to($main);

$play = $controls_widget->insert(
    Button =>
    checkable => 1,
    enabled => 0,
    text => symbol("PLAY"),
    onClick => sub ($widget) {
        if ($widget->checked) {
            $widget->backColor(cl::LightRed);
            $widget->text(symbol("PAUSE"));
            $server->add_voices(
                # FIXME: Our Voices are different from those of the
                # sound project!
            );
        }
        else {
            $widget->backColor(cl::White);
            $widget->text(symbol("PLAY"));
        }
    },
    pack => { side => 'left', fill => 'both' },
);

my $o_window;
my $oscilloscope;
sub toggle_oscilloscope {
    if ($o_window) {
        $o_window->destroy;
        undef $o_window;
        return;
    }
    $o_window = $main->insert(
        Window =>
        parent => $main,
        size => [400,400],
        text => 'Aoede Oscilloscope',
        onClose => sub { undef $o_window },
    );
    $oscilloscope = Audio::Aoede::UI::Oscilloscope->new(
        parent    => $o_window,
        frequency => 440,
        rate      => $rate,
        source    => $server,
        size      => [400,400],
        pack      => { side => 'top', fill => 'both' },
    );
}


sub tick {
    say "ticked";
    for (values %timer_objects) {
        $_->update();
    }
}

sub register_timer ($object) {
    if (! scalar keys %timer_objects) {
        $timer->start;
    }
    $timer_objects{refaddr $object} = $object;
}

sub unregister_timer ($object) {
    delete $timer_objects{refaddr $object};
    if (! scalar keys %timer_objects) {
        $timer->stop;
    }
}


Prima->run;
