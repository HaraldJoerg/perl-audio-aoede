package Audio::Aoede::Functions 0.01;
use 5.036;

use feature 'signatures';
no warnings 'experimental';

use Exporter qw( import );

BEGIN {
    our @EXPORT_OK = qw( confine );
    our %EXPORT_TAGS = (
        waves => [ qw( f_sine_wave
                       f_square_wave
                       f_sawtooth_wave
                 )],
    );
    Exporter::export_ok_tags('waves');
}
use PDL;

use Audio::Aoede::Units qw( PI );


sub confine {
    my ($value,$min,$max) = @_;
    if ($value < $min) {
        $value = $min;
    }
    elsif ($value > $max) {
        $value = $max;
    }
    return $value;
}


sub f_sine_wave ($rate) {
    return sub ($n_samples, $frequency, $since = 0) {
        my $samples_per_period = $rate / $frequency;
        my $norm = 2 * PI() / $samples_per_period;
        $since -= $samples_per_period * int $since/$samples_per_period;
        my $phase = (sequence($n_samples) + $since) * $norm;
        my $samples = sin($phase);
        return $samples;
    }
}


sub f_square_wave ($rate) {
    return sub ($n_samples, $frequency, $since = 0) {
        my $total_periods      = $since * $frequency / $rate;
        my $samples_per_period = $rate / $frequency;
        my $low_part           = 0.5;
        my $partial_period     = $total_periods - int($total_periods);
        my $phase              = sequence($n_samples) / $samples_per_period;
        $phase                 += $partial_period;
        $phase                 -= long $phase;
        my ($lo,$hi)           = $phase->where_both($phase < $low_part);
        $lo .= -1;
        $hi .= 1;
        return $phase;
    }
}


sub f_sawtooth_wave ($rate) {
    return sub ($n_samples, $frequency, $since = 0) {
        my $total_periods      = $since * $frequency / $rate;
        my $samples_per_period = $rate / $frequency;
        my $partial_period     = $total_periods - int($total_periods);
        my $phase              = sequence($n_samples) / $samples_per_period;
        $phase                 += $partial_period;
        $phase                 -= long $phase;
        $phase                 *= 2;
        $phase                 -= 1;
        return $phase;
    }
}

1;
