use 5.032;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Audio::Aoede::LPCM;

my $path = '/home/haj/devel/projects/sound/sounds/kaedish_gallery.wav';
my $lpcm = Audio::Aoede::LPCM->new_from_wav($path);
$lpcm->write_wav('/tmp/kaedish.wav');
system('sox', '-q', '/tmp/kaedish.wav', '-d');
