use 5.032;
use lib 'lib';
my $path = $ARGV[0] || 'eg/e.mrt';
use Audio::Aoede::MusicRoll;
use Audio::Aoede qw( sine_wave );
use Audio::Aoede::Voice;

my $music_roll = Audio::Aoede::MusicRoll->from_file($path);

my $muse = Audio::Aoede->new(
    player => 'sox',
);

my @voices;

for my $section ($music_roll->sections) {
    my $i_track = 0;
    Audio::Aoede::Units::set_bpm($section->bpm);
    for my $track ($section->tracks) {
        $voices[$i_track] //=  Audio::Aoede::Voice->new(function => sine_wave());
        $voices[$i_track]->add_notes(@$track);
        $i_track++;
    }
}
$muse->write(@voices);

say "Done!";

use Encode;
sub e {
    Encode::encode('UTF-8',shift);
}
