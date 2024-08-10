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

# D6:𝅘𝅥𝅯 E6:𝅘𝅥𝅯 C6:𝅘𝅥𝅯 A5:𝅘𝅥𝅮 B5:𝅘𝅥𝅯 G5:𝅘𝅥𝅮        D5:𝅘𝅥𝅯 E5:𝅘𝅥𝅯 C5:𝅘𝅥𝅯 A4:𝅘𝅥𝅮 B4:𝅘𝅥𝅯 G4:𝅘𝅥𝅮
# D4:𝅘𝅥𝅯 E4:𝅘𝅥𝅯 C4:𝅘𝅥𝅯 A3:𝅘𝅥𝅮 B3:𝅘𝅥𝅯 A3:𝅘𝅥𝅯 A♭3:𝅘𝅥𝅯  G3:𝅘𝅥𝅮 𝄾 G5+D5+B4+G4:𝅘𝅥𝅮
my @scores;
$scores[0] = <<END_OF_SCORE;
D4:𝅘𝅥𝅯 D♯4:𝅘𝅥𝅯
E4:𝅘𝅥𝅯 C5:𝅘𝅥𝅮 E4:𝅘𝅥𝅯 C5:𝅘𝅥𝅮 E4:𝅘𝅥𝅯 A4+C5:6/16 E4+C5:𝅘𝅥𝅯 F4+D5:𝅘𝅥𝅯 F♯4+D♯5:𝅘𝅥𝅯
G4+E5:1/16 E4+C5:1/16 F4+D5:1/16 G4+E5:1/8 D4+B4:1/16 F4+B4+D5:1/8
E4+G4+C5:3/8 D4:𝅘𝅥𝅯 D♯4:𝅘𝅥𝅯
E4:𝅘𝅥𝅯 C5:𝅘𝅥𝅮 E4:𝅘𝅥𝅯 C5:𝅘𝅥𝅮 E4:𝅘𝅥𝅯 A4+C5:7/16 C4+A4:1/16 G4:1/16
END_OF_SCORE

# D5:𝅘𝅥𝅯 E5:𝅘𝅥𝅯 C5:𝅘𝅥𝅯 A4:𝅘𝅥𝅮 B4:𝅘𝅥𝅯 G4:𝅘𝅥𝅮        D4:𝅘𝅥𝅯 E4:𝅘𝅥𝅯 C4:𝅘𝅥𝅯 A3:𝅘𝅥𝅮 B3:𝅘𝅥𝅯 G3:𝅘𝅥𝅮
# D3:𝅘𝅥𝅯 E3:𝅘𝅥𝅯 C3:𝅘𝅥𝅯 A2:𝅘𝅥𝅮 B2:𝅘𝅥𝅯 A2:𝅘𝅥𝅯 A♭2:𝅘𝅥𝅯  G2:𝅘𝅥𝅮 𝄾 B3+D3+G2:𝅘𝅥𝅮
$scores[1] = <<END_OF_SCORE;
𝄾
C3:𝅘𝅥𝅮 G3+C4:𝅘𝅥𝅮 G2:𝅘𝅥𝅮 G3+B♭3:𝅘𝅥𝅮 F2:𝅘𝅥𝅮 A3+C3:𝅘𝅥𝅮 E2:𝅘𝅥𝅮 G3+C4:1/8
G2:1/8 G3:1/8 G2:1/8 G3:1/8
C3:1/8 G3:1/8 C4:1/8 G3+B3:1/8
C3:𝅘𝅥𝅮 G3+C4:𝅘𝅥𝅮 G2:𝅘𝅥𝅮 G3+B♭3:𝅘𝅥𝅮 F2:𝅘𝅥𝅮 A3+C3:𝅘𝅥𝅮 E2+E3:𝅘𝅥𝅮 Eb2+Eb3:𝅘𝅥𝅮
END_OF_SCORE

my @voices = map {
    my $voice = Audio::Aoede::Voice->new(function => sine_wave());
    $voice->add_named_notes($scores[$_]);
    $voice;
} (0..1);
$muse->write(@voices);
