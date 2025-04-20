use strict;
use warnings;
use Test::More;
use PDL;
use Test::PDL;
use Audio::Aoede::SoundFont::Resample;

my $sample = sequence(20)->float;

{
    my $rates = pdl([2, 2, 2, 2, 2]);
    my $state = pdl(0);
    my $out = resample_with_loop($sample, $rates, $state, 2, 7);
    ok($out->nelem == 5, 'Output length matches rates');
    is_pdl($out,pdl([2, 4, 6, 3, 5]),
           'Simple interpolation with wrap-around works'); # one wrap-around
}

{
    my $rates = pdl([1, 1, 3, 5, 7]);
    my $state = pdl(0);
    my $out = resample_with_loop($sample, $rates, $state, 2, 7);
    is_pdl($out,pdl([1, 2, 5, 5, 2]),
           'Simple interpolation with wrap-around works'); # one wrap-around
}

done_testing;
