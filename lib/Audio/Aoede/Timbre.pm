# ABSTRACT: How tones actually sound
use 5.036;
package Audio::Aoede::Timbre;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Timbre;
use PDL;
use constant PI => atan2(0,-1);
use Audio::Aoede;

field $effects   :param = [];
field @effects;
field $harmonics :param = [1.0];
field @harmonics :reader;
field $generator :param :reader = undef;


ADJUST {
    if (! $generator) {
        require Audio::Aoede::Generator::Sine;
        $generator = Audio::Aoede::Generator::Sine->new(
            rate => Audio::Aoede->instance->rate,
        );
    }

    @harmonics = @$harmonics;
    undef $harmonics;

    @effects = @$effects;
    undef $effects;
}


method add_effects (@new) {
    push @effects,@new;
    return $self;
}


method set_harmonics (@list) {
    @harmonics = @list;
}


method effects () {
    return @effects;
}

1;
