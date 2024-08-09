use 5.032;
use warnings;
use utf8; # for the scores
use FindBin;
use lib "$FindBin::Bin/../lib";

use Audio::Aoede qw( sine_wave );
use Audio::Aoede::Voice;

Audio::Aoede::Units::set_tempo(750_000);

my $muse = Audio::Aoede->new(
   player => 'sox',
);

my @scores;
$scores[0] = <<END_OF_SCORE;
D6:𝅘𝅥𝅯 E6:𝅘𝅥𝅯 C6:𝅘𝅥𝅯 A5:𝅘𝅥𝅮 B5:𝅘𝅥𝅯 G5:𝅘𝅥𝅮        D5:𝅘𝅥𝅯 E5:𝅘𝅥𝅯 C5:𝅘𝅥𝅯 A4:𝅘𝅥𝅮 B4:𝅘𝅥𝅯 G4:𝅘𝅥𝅮
D4:𝅘𝅥𝅯 E4:𝅘𝅥𝅯 C4:𝅘𝅥𝅯 A3:𝅘𝅥𝅮 B3:𝅘𝅥𝅯 A3:𝅘𝅥𝅯 A♭3:𝅘𝅥𝅯  G3:𝅘𝅥𝅮 𝄾 G5:𝅘𝅥𝅮
END_OF_SCORE

$scores[1] = <<END_OF_SCORE;
D5:𝅘𝅥𝅯 E5:𝅘𝅥𝅯 C5:𝅘𝅥𝅯 A4:𝅘𝅥𝅮 B4:𝅘𝅥𝅯 G4:𝅘𝅥𝅮        D4:𝅘𝅥𝅯 E4:𝅘𝅥𝅯 C4:𝅘𝅥𝅯 A3:𝅘𝅥𝅮 B3:𝅘𝅥𝅯 G3:𝅘𝅥𝅮
D3:𝅘𝅥𝅯 E3:𝅘𝅥𝅯 C3:𝅘𝅥𝅯 A2:𝅘𝅥𝅮 B2:𝅘𝅥𝅯 A2:𝅘𝅥𝅯 A♭2:𝅘𝅥𝅯  G2:𝅘𝅥𝅮 𝄾 B3:𝅘𝅥𝅮
END_OF_SCORE

$scores[2] = <<END_OF_SCORE;
R:7/4 D5:𝅘𝅥𝅮
END_OF_SCORE

$scores[3] = <<END_OF_SCORE;
R:7/4 B4:𝅘𝅥𝅮
END_OF_SCORE

$scores[4] = <<END_OF_SCORE;
R:7/4 G4:𝅘𝅥𝅮
END_OF_SCORE

$scores[5] = <<END_OF_SCORE;
R:7/4 D3:𝅘𝅥𝅮
END_OF_SCORE

$scores[6] = <<END_OF_SCORE;
R:7/4 G2:𝅘𝅥𝅮
END_OF_SCORE

my @voices = map {
    my $voice = Audio::Aoede::Voice->new(function => sine_wave());
    $voice->add_named_notes($scores[$_]);
    $voice;
} (0..6);
$muse->write(@voices);
