use strict;
use feature "signatures";
no warnings "experimental";

use Prima;
use Prima::Application name => 'Sound from Scratch';
use PDL::Graphics::Prima;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Audio::Aoede::Server;
use Audio::Aoede::UI::Oscilloscope;
use Audio::Aoede::Units qw( symbol );

######################################################################
# Configuration hardwired right now
my $tick = 1/60;  # in synch with my graphics card
my $rate = 48000; # e have 800 samples per second

my $server = Audio::Aoede::Server->new(
    rate => $rate,
);

my $main = Prima::MainWindow->create(
    text  => 'Sound from Scratch',
    backColor => cl::White,
    size => [600,600],
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
        }
        else {
            $widget->backColor(cl::White);
            $play->checked(0);
            $play->enabled(0);
            $play->text(symbol("PLAY"));
            $play->backColor(cl::White);
            $server->stop;
        }
    },
    pack => { side => 'left', fill => 'both' },
);
$play = $controls_widget->insert(
    Button =>
    checkable => 1,
    enabled => 0,
    text => symbol("PLAY"),
    onClick => sub ($widget) {
        if ($widget->checked) {
            $widget->backColor(cl::LightRed);
            $widget->text(symbol("PAUSE"));
            $server->start;
        }
        else {
            $widget->backColor(cl::White);
            $widget->text(symbol("PLAY"));
            $server->stop;
        }
    },
    pack => { side => 'left', fill => 'both' },
);

my $sliders = $main->insert(
    Widget =>
    backColor => cl::White,
    pack =>  { side => 'top', fill => 'both' },
);
my $slider_size = [25,100];
my $slider1 = $sliders->insert(
    Slider =>
    vertical => 1,
    pack => { side => 'left', fill => 'both' },
    value => 55,
    autoTrack => 1,
    min => 0,
    max => 100,
    scheme => ss::Axis,
    ticks => [],
    increment => 1,
    size => $slider_size,
    ribbonStrip => 1,
    borderWidth => 2,
);
my $slider2 = $sliders->insert(
    Slider =>
    vertical => 1,
    pack => { side => 'left', fill => 'both' },
    value => 55,
    autoTrack => 1,
    min => 0,
    max => 100,
    scheme => ss::Axis,
    ticks => [],
    increment => 1,
    size => $slider_size,
    ribbonStrip => 1,
    borderWidth => 2,
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

Prima->run;
