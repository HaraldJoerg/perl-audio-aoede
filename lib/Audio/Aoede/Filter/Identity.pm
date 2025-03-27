# Abstract: An Aoede filter which does not change anything
package Audio::Aoede::Filter::Identity;
use 5.038;

use Feature::Compat::Class;

class Audio::Aoede::Filter::Identity;

use PDL;
use PDL::FFT;

method filter ($data) {
    my $float = float($data);
    realfft($float);
    my $separator = $float->dim(0)/2;
    # ---
    # Hack: A radical lowpass filter
    #$float->slice([$separator*0.03,$separator-1]) .= 0;
    #$float->slice([$separator*1.03,2*$separator-1]) .= 0;
    # ---
    # linear decay
    # my $decay = 1 - (sequence($separator)) / $separator;
    # $float->slice([0,$separator-1]) *= $decay;
    # $float->slice([$separator,-1]) *= $decay;
    # ---
    # linear rise
    # my $decay = (sequence($separator) +1) / $separator;
    # $float->slice([0,$separator-1]) *= $decay;
    # $float->slice([$separator,-1]) *= $decay;
    # ---
    # exponential decay
    # my $x_factor = 100;
    # my $sequence = exp(- $x_factor * (sequence($separator) +1) / $separator);
    # $float->slice([0,$separator-1]) *= $sequence;
    # $float->slice([$separator,-1]) *= $sequence;
    realifft($float);
    return short($float);
}

1;
