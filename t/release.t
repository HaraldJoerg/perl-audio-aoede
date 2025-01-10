use 5.032;
use feature 'signatures';
no warnings 'experimental';

use Test::More;
use Test::PDL;

use Audio::Aoede;
use Audio::Aoede::Notes;
use Audio::Aoede::Envelope::ADSR;
use PDL;

my $rate = 12;
my $A = Audio::Aoede->new(rate => $rate);

my $samples6 = pdl(-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1);
my $samples3 = pdl(-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1);
my $release_samples = pdl(    -0.9,0.8,-0.7,0.6,-0.5,0.4,-0.3,0.2,-0.1,0);

{
    my $track = [
        Audio::Aoede::Notes->new(pitches => [6], duration => 1),
    ];

    my $release = 10;
    my $voice =  Audio::Aoede::Voice->new(
        function => $A->square_wave(),
        rate     => $rate,
    );
    $voice->add_notes($track,240);

    is ($voice->samples->dim(0),$rate,
        "Single test: We got $rate samples");
    my $expected = $samples6;
    is_pdl($voice->samples,$expected,
           "The samples are ok");
    is ($voice->carry->dim(0),$release,
        "We got $release samples for the release phase");
    is_pdl($voice->carry,$release_samples,
           "The carry is ok");
}

{
    my $track = [
        Audio::Aoede::Notes->new(pitches => [6], duration => 1),
        Audio::Aoede::Notes->new(pitches => [6], duration => 1),
    ];

    my $release = 10;
    my $voice =  Audio::Aoede::Voice->new(
        function => $A->square_wave(),
        rate     => $rate,
    );
    $voice->add_notes($track,240);

    is ($voice->samples->dim(0),2*$rate,
        "Append test: We got 2*$rate samples");
    my $expected = pdl($samples6->append($samples6));
    $expected->slice([$rate,$rate+$release-1]) += $release_samples;
    is_pdl($voice->samples,$expected,
           "The samples are ok");
    is ($voice->carry->dim(0),$release,
        "We got $release samples for the release phase");
    $expected = pdl(    -0.9,0.8,-0.7,0.6,-0.5,0.4,-0.3,0.2,-0.1,0);
    is_pdl($voice->carry,$expected,
           "The carry is ok");
}

{
    # Start release halfway in attack
    my $track = [
        Audio::Aoede::Notes->new(pitches => [6], duration => 1),
    ];
    my $release = 10;
    my $voice =  Audio::Aoede::Voice->new(
        function => $A->square_wave(),
        rate     => $rate,
    );
    $voice->add_notes($track,240);
    is ($voice->samples->dim(0),$rate,
        "Attack test: We got $rate samples");
    my $expected = pdl( [-0.05,0.1,-0.15,0.2,-0.25,0.3,
                         -0.35,0.4,-0.45,0.5,-0.55,0.6]);
    my $last = $expected->at(-1);
    is_pdl($voice->samples,$expected,
           "The samples are ok");
    is ($voice->carry->dim(0),$release,
        "We got $release samples for the release phase");
    $expected = pdl(-0.9,0.8,-0.7,0.6,-0.5,0.4,-0.3,0.2,-0.1,0) * $last;
    is_pdl($voice->carry,$expected,
           "The carry is ok");
}

{
    # Start release halfway in decay
    my $track = [
        Audio::Aoede::Notes->new(pitches => [6], duration => 1),
    ];
    my $release = 10;
    my $voice =  Audio::Aoede::Voice->new(
        function => $A->square_wave(),
        rate     => $rate,
    );
    $voice->add_notes($track,240);
    is ($voice->samples->dim(0),$rate,
        "Decay test: We got $rate samples");
    my $expected = pdl( [-0.95,0.9,-0.85,0.8,-0.75,0.7,
                         -0.65,0.6,-0.55,0.5,-0.45,0.4]);
    my $last = $expected->at(-1);
    is_pdl($voice->samples,$expected,
           "The samples are ok");
    is ($voice->carry->dim(0),$release,
        "We got $release samples for the release phase");
    $expected = pdl(-0.9,0.8,-0.7,0.6,-0.5,0.4,-0.3,0.2,-0.1,0) * $last;
    is_pdl($voice->carry,$expected,
           "The carry is ok");
}

sub envelope ($attack,$decay,$sustain,$release) {
    return sub ($frequency) {
        return Audio::Aoede::Envelope::ADSR->new(
            attack  => $attack,
            decay   => $decay,
            sustain => $sustain,
            release => $release,
        );
    }
}

done_testing;
