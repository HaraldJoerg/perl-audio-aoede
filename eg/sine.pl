use 5.032;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';


use Audio::Aoede qw( sine_wave );

use Audio::Aoede::LPCM;
my $wave = sine_wave(440);
my $samples = $wave->(Audio::Aoede->rate);
Audio::Aoede::write_wav($samples);
