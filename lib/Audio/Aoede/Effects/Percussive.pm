# ABSTRACT: Start a tone/sound with inharmonic noise
use 5.038;
package Audio::Aoede::Effects::Percussive;

use Feature::Compat::Class;
no warnings 'experimental';

class Audio::Aoede::Effects::Percussive;

use PDL;

use Audio::Aoede;
use Audio::Aoede::Noise;

field $frequency :param;
field $width     :param;
field $duration  :param;
field $intensity :param;
field $noise;

ADJUST {
    my $rate = Audio::Aoede->instance->rate;
    $duration = int ($rate * $duration); # Switch from seconds to samples
    my $dummy = zeroes($duration);
    my $amplitude = $dummy->xlinvals(1.0,0.0) * $intensity;
    $noise = Audio::Aoede::Noise->gaussian(
        frequency => $frequency,
        width     => $width,
        rate      => $rate,
    )->next_samples($duration,0) * $amplitude;
}


sub generate ($class,$min,$max,$duration) {
    $class->new(
        min_frequency => $min,
        max_frequency => $max,
        duration      => $duration,
    );
}


method apply ($samples,$offset) {
    my $todo = $duration - $offset;
    if ($todo < 0) {
        return $samples;
    }
    else {
        my $n_samples = $samples->dim(0);
        if ($n_samples > $todo) {
            $samples->slice([0,$todo-1]) += $noise->slice([$offset,$duration-1]);
        }
        else {
            $samples += $noise->slice([$offset,$offset+$n_samples-1]);
        }
        return $samples;
    }
}


method release ($offset) {
    return pdl([]);
}

1;
__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Effects::Percussive - bring on the drums

=head1 SYNOPSIS

  use Audio::Aoede::Effects::Percussive;
  # Well, don't.  This is a mess.

=head1 DESCRIPTION

This class is supposed to add some non-harmonic noise to a
L<Audio::Aoede::Timbre> as an effect.  The motivation for that is that
non-harmonic frequencies are often only audible at the beginning of
the tone, while the harmonic frequencies have longer decay times due
to resonance.  Our current timbre implementation treats envelopes as
effects and only allows one single envelope which makes things messy.

This is too difficult to handle, I would like to get rid of it.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

