# ABSTRACT: One musical tone, or a chord of musical tones
use 5.036;
package Audio::Aoede::Tone;

use Feature::Compat::Class;
no warnings 'experimental';

class Audio::Aoede::Tone;

use PDL ();
use builtin qw( indexed );
use constant PI => atan2(0,-1);

use Audio::Aoede::Source;
use Audio::Aoede::Units qw( seconds_per_note );

field $intensity :param = 1;
field $duration  :param = undef; # in "notes" units
field $pitches   :param;
field @overtones;


method next_samples ($n_samples,$first = 0) {
    my $samples = PDL->zeroes($n_samples);
    for my $overtone (@overtones) {
        $samples += $overtone->next_samples($n_samples);
    }
    return $samples;
}


method trailer ($first) {
    my @carry = map { $_->trailer($first) } @overtones;
    my $carry = PDL->pdl(@carry)->transpose->sumover;
    return $carry;
}


method sequence ($rate,$bpm,$timbre) {
    my $generator = $timbre->generator;
    for my $frequency (@$pitches) {
      OVERTONE:
        for my ($index,$harmonic) (indexed $timbre->harmonics) {
            next OVERTONE unless $harmonic;
            $index += 1;
            my $resonance = $index * $index;
            push @overtones, Audio::Aoede::Source->new(
                rate => $rate,
                volume => $harmonic,
                function => $generator->function($index * $frequency),
                effects => [map {$_->($resonance * $frequency) }
                            $timbre->effects],
            );
        }
    }
    my $n_samples =  $duration * seconds_per_note($bpm) * $rate;
    my $samples = PDL->zeroes($n_samples);
    for my $overtone (@overtones) {
        $samples += $overtone->next_samples($n_samples);
    }
    my @carry = map { $_->trailer($n_samples) } @overtones;
    my $carry = PDL->pdl(@carry)->transpose->sumover;
    return ($intensity * $samples,$intensity * $carry);
}

1;
