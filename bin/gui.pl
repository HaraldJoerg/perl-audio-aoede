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

use Audio::Aoede;
use Audio::Aoede::Server;
use Audio::Aoede::Note;
use Audio::Aoede::Player::SoX;
use Audio::Aoede::Source;
use Audio::Aoede::UI::Envelope;
use Audio::Aoede::UI::Oscilloscope;
use Audio::Aoede::UI::Register;
use Audio::Aoede::UI::Tuner;
use Audio::Aoede::Units qw( symbol );

######################################################################
# Configuration hardwired right now
my $tick = 1/60;  # in synch with my graphics card
my $rate = 48000; # we have 800 samples per second
my $bits = 16;    # Where should this be defined?
my $channels = 1; # Where should this be defined?
my $max_frequency = 22000;
my %timer_objects;
my $silent = 1;

my $aoede = Audio::Aoede->new(
    rate => $rate,
);
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

my $player = Audio::Aoede::Player::SoX->new(
    rate	=> $rate,
    # encoding	=> $encoding,
    bits	=> $bits,
    channels	=> $channels,
    source      => $server,
);
$player->connect($server);

my $oscilloscope;
my ($power,$play,$speaker);
$power = $controls_widget->insert(
    Button =>
    checkable => 1,
    text => symbol("POWER"),
    onClick => sub ($widget) {
        $play->checked(0);
        $speaker->enabled(0);
        if ($widget->checked) {
            $widget->backColor(cl::LightRed);
            $play->enabled(1);
        }
        else {
            $widget->backColor(cl::White);
            $play->enabled(0);
            $play->text(symbol("PLAY"));
            if ($speaker->checked) {
                $speaker->notify('Click');
            }
            %timer_objects = ();
        }
    },
    pack => { side => 'left', fill => 'both' },
);


my $register = Audio::Aoede::UI::Register->new();
$register->insert_to($main);

my $tuner = Audio::Aoede::UI::Tuner->new();
$tuner->insert_to($main);

my $envelope_ui = Audio::Aoede::UI::Envelope->new();
$envelope_ui->insert_to($main);

my $key = $main->insert(
    Button =>
    pack => { side => 'top' },
    text => 'Play',
    hotkey => ' ',
    onMouseDown => sub {
        $player->unmute;
        $silent = 0;
        reset_sources();
    },
    onMouseUp => sub {
        $silent = 1;
        reset_sources();
    },
    onKeyDown => sub ($widget,$code,@rest) {
        return unless defined $code;
        if (chr $code  eq  ' ') {
            $silent = 0;
            reset_sources();
            $player->unmute;
        }
    },
    onKeyUp => sub ($widget,$code,@rest) {
        return unless defined $code;
        if (chr $code  eq  ' ') {
            $server->set_sources();
        }
    },
);

$play = $controls_widget->insert(
    Button =>
    checkable => 1,
    enabled => 0,
    text => symbol("PLAY"),
    onClick => sub ($widget) {
        if ($widget->checked) {
            $widget->text(symbol("PAUSE"));
            reset_sources();
            $speaker->enabled(1);
            register_timer($player);
            $player->start;
            if ($oscilloscope) {
                register_timer($oscilloscope);
            }
        }
        else {
            $widget->backColor(cl::White);
            $widget->text(symbol("PLAY"));
            $server->set_sources();
            if ($speaker->checked) {
                $speaker->notify('Click');
            }
            $speaker->enabled(0);
            $player->stop;
            unregister_timer($player);
            if ($oscilloscope) {
                unregister_timer($oscilloscope);
                $oscilloscope->update;
            }
        }
    },
    pack => { side => 'left', fill => 'both' },
);

$speaker =  $controls_widget->insert(
    Button =>
    checkable => 1,
    enabled => 0,
    text => symbol("LOOP"),
    onClick => sub ($widget) {
        if ($widget->checked) {
            $widget->text(symbol("MUTE"));
            $player->unmute;
            $silent = 0;
            reset_sources();
        }
        else {
            $widget->text(symbol("LOOP"));
            $player->mute;
            $silent = 1;
            reset_sources();
        }
    },
    pack => { side => 'left', fill => 'both' },
);



sub reset_sources {
    my @sources = ();
    my $base_frequency = $tuner->value;
    if (! $silent  &&  $base_frequency) { # User can dial it to zero
        my @volumes = $register->volumes;
        my $harmonic = 0;
      REGISTER_SOURCES:
        for my $volume (@volumes) {
            my $frequency = $base_frequency * $harmonic++;
            last REGISTER_SOURCES if $frequency > $max_frequency;
            push @sources, Audio::Aoede::Source->new(
                volume => $volume,
                function => sub ($n_samples, $since) {
                    $aoede->sine_wave->($n_samples,
                                        $frequency,
                                        $since
                                    );
                },
            );
        }
    }
    $server->set_sources(@sources);
}


$register->set_trigger(\&reset_sources);
$tuner->set_trigger(\&reset_sources);

my $o_window;
sub toggle_oscilloscope {
    if ($o_window) {
        $o_window->destroy; # also unregisters the oscilloscope
        undef $o_window;
        undef $oscilloscope;
        return;
    }
    $o_window = $main->insert(
        Window =>
        parent => $main,
        size => [400,400],
        text => 'Aoede Oscilloscope',
        onClose => sub { undef $o_window },
        onDestroy => sub { unregister_timer($oscilloscope) },
    );
    $oscilloscope = Audio::Aoede::UI::Oscilloscope->new(
        parent    => $o_window,
        frequency => 440,
        rate      => $rate,
        source    => $server,
        size      => [400,400],
        pack      => { side => 'top', fill => 'both' },
    );
    register_timer($oscilloscope);
}


sub tick {
    $server->update;
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
