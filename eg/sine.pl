use 5.032;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Audio::Aoede qw( sine_wave );
use Audio::Aoede::Voice;

my $muse = Audio::Aoede->new(
    player => 'sox',
);

my $voice = Audio::Aoede::Voice->new(
    function => sine_wave()
);

$voice->add_named_note('A4',1/4);
$voice->add_named_note('A5',1/4);
$voice->add_named_note('A3',1/4);
$voice->add_named_note('A4',3/4);

$muse->write($voice);

#my $player = $muse->player;
#$player->write($voice->samples);
