use 5.032;
use warnings;
use utf8; # for the scores
use FindBin;
use lib "$FindBin::Bin/../lib";

use Audio::Aoede qw( sine_wave );
use Audio::Aoede::Voice;

my $muse = Audio::Aoede->new(
   player => 'sox',
);

my $bigben = <<END_OF_SCORE;
A3:𝅘𝅥  C♯4:𝅘𝅥 B3:𝅘𝅥  E3:𝅗𝅥
A3:𝅘𝅥  B3:𝅘𝅥  C♯4:𝅘𝅥 A3:𝅗𝅥
C♯4:𝅘𝅥 A3:𝅘𝅥  B3:𝅘𝅥  E3:𝅗𝅥
E3:𝅘𝅥  B3:𝅘𝅥  C♯4:𝅘𝅥 A3:𝅗𝅥
END_OF_SCORE


my $voice = Audio::Aoede::Voice->new(function => sine_wave());
for my $note (split /\s+/, $bigben) {
    next unless $note;
    $voice->add_named_note($note);
}
$muse->write($voice);

my $bigben_ascii = <<END_OF_SCORE;
A3:1/4  C#4:1/4 B3:1/4  E3:1/2
A3:1/4  B3:1/4  C#4:1/4 A3:1/2
C#4:1/4 A3:1/4  B3:1/4  E3:1/2
E3:1/4  B3:1/4  C#4:1/4 A3:1/2
END_OF_SCORE

my $voice = Audio::Aoede::Voice->new(function => sine_wave());
for my $note (split /\s+/, $bigben_ascii) {
    next unless $note;
    $voice->add_named_note($note);
}
$muse->write($voice);
