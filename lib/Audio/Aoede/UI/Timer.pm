# Abstract: Manage timer callbacks for Aoede UIs
package Audio::Aoede::UI::Timer;

use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::Timer;

use builtin qw( refaddr );
use Time::HiRes qw( gettimeofday tv_interval time);
use Audio::Aoede::Functions qw( confine );

field $fps :param :reader;
field $timer;
field %callbacks;
field $timer_stopping;
field $previous_time;

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




method start () {
    $previous_time = time;
    $timer_stopping = 0;
    $timer->start;
}


method pause () {
    $timer_stopping = 1;
    $timer->stop;
    %callbacks = ();
}


method stop () {
    $timer_stopping = 1;
    $timer->stop;
    %callbacks = ();
}


method set_fps ($fps) {
    confine($fps,0.1,200);
    $timer->timeout(1000/$fps);
}


method tick {
    my $now = time;
    for my $callback (values %callbacks) {
        $callback->($now-$previous_time);
    }
    $previous_time = $now;
}
1;
