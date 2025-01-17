# Abstract: Manage timer callbacks for Aoede UIs
package Audio::Aoede::UI::Timer;

use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::Timer;

use builtin qw( refaddr );
use Time::HiRes qw( gettimeofday tv_interval );

field $fps :param :reader;
field $timer;
field %callbacks;
field $offset;
field $start_time;
field $current_t;
field $clear_callbacks;

ADJUST {
    no warnings 'once';
    $timer = $::application->insert(
        Timer =>
        timeout => 1000 / $fps,
        onTick  => sub { $self->tick() }
    );
}


method add_callback ($coderef) {
    $callbacks{refaddr $coderef} = $coderef;
}


method reset_time () {
    $offset = 0;
}


method start () {
    $start_time = [gettimeofday];
    $clear_callbacks = 0;
    $timer->start;
}


method pause () {
    $clear_callbacks = 1;
    $timer->stop;
    $offset = $current_t;
    %callbacks = ();
}


method stop () {
    $clear_callbacks = 1;
    $timer->stop;
    $offset = 0;
    %callbacks = ();
}


method shift_time ($by) {
    $offset += $by;
}


method set_fps ($fps) {
    $fps  and  $timer->timeout(1000/$fps);
}


method tick {
    if ($clear_callbacks) {
    }
    else {
        $current_t = $offset + tv_interval($start_time);
        for my $callback (values %callbacks) {
            $callback->($current_t);
        }
    }
}
1;
