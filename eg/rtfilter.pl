use 5.038;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw( tv_interval gettimeofday );
use PDL 2.099;

use Audio::Aoede;
use Audio::Aoede::File;
use Audio::Aoede::Filter::Identity;
use Audio::Aoede::Player::SoX;
use Audio::Aoede::Recorder::SoX;
use builtin qw( indexed );
no warnings 'experimental';

my $rate     = 48000;
my $bits     = 16;
my $channels = 2;

my $player = Audio::Aoede::Player::SoX->new(
    rate     => $rate,
    bits     => $bits,
    channels => $channels,
    out      => 'junkyard/filtered.ogg',
);
$player->open_pipe;

my $filter = Audio::Aoede::Filter::Identity->new();

my $path = $ARGV[0] || 'junkyard/kaedish_gallery.ogg';
my $object = Audio::Aoede::File->pipe_from_file($path);

my $batch = 4800;
# FIXME: This logic is supposed to vanish into one of the classes.
# But which one? AA::File?  AA::Recorder?
my $up = sequence($batch/2) / ($batch/2);
my $down = ones($batch/2) - $up;
my @unfiltered = map { zeroes($batch) } (1..$channels);
my @filtered;
my @saved = map { zeroes($batch/2) } (1..$channels);;
while (defined (my $data = $object->read_pipe($batch/2))) {
    my $sound = short zeroes($channels,length($data)/$channels/2);
    $sound->update_data_from($data);
    my @channels = $sound->transpose->dog;

    for my ($index,$channel) (indexed @channels) {
        $unfiltered[$index]->slice([$batch/2,$batch-1]) .= $channel * $down;
        $filtered[$index] = $filter->filter($unfiltered[$index]);
        $filtered[$index]->slice([0,$batch/2-1]) += $saved[$index];
        $saved[$index] = $filtered[$index]->slice([$batch/2,$batch-1]);
    }
    $sound = cat(@filtered)->transpose;
    $player->send_piddle($sound->slice([],[0,$batch/2-1]));
    for my ($index,$channel) (indexed @channels) {
        $unfiltered[$index]->slice([0,$batch/2-1]) .=
            $channel * $up;
    }
}
