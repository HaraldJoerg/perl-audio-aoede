use Test::More;
use PDL;
use Test::PDL;

use Audio::Aoede::SoundFont::ModEnv;

{
    my $env = Audio::Aoede::SoundFont::ModEnv->new(
        rate    => 1,
        delay   => 1,
        attack  => 2,
        hold    => 3,
        decay   => 5,
        sustain => 0.5,
        release => 5
    );
    my $full = pdl(0,                   # start is always 0
                   0,                   # delay
                   0.5,1,               # attack
                   1,1,1,               # hold
                   1.0,0.9,0.8,0.7,0.6, # decay
                   (0.5) x 20);         # sustain
    {
        my $get = $env->env_samples(0,10);
        is_pdl($get,$full->slice([0,9]),
               'Request fits into samples');
    }

    {
        my $get = $env->env_samples(3,10);
        is_pdl($get,$full->slice([3,12]),
               'Not starting at first sample');
    }

    {
        my $get = $env->env_samples(8,10);
        is_pdl($get,$full->slice([8,17]),
               'Starting in decay phase');
    }

    {
        my $get = $env->env_samples(15,10);
        is_pdl($get,$full->slice([15,24]),
               'Sustain only');
    }
}



done_testing;

