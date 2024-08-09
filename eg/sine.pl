use 5.032;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Audio::Aoede qw( sine_wave );
use Audio::Aoede::Voice;

my $muse = Audio::Aoede->new(
   player => 'sox',
);

my $voice = Audio::Aoede::Voice->new(function => sine_wave());
$voice->add_named_notes(' A4:1 ');
$muse->write($voice);
