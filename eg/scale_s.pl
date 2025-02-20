use Audio::Aoede::Timbre;
my $rate = 44100;
return (
    {
        timbre => Audio::Aoede::Timbre->new(
            generator => Audio::Aoede::Generator::Sine->new(),
        ),
        channels  => { left => 0.2, right => 0.8 },
    }
);
