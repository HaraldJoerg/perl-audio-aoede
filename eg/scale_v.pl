use Audio::Aoede::Timbre::Vibraphone;
my $rate = 44100;
return (
    { timbre    => Audio::Aoede::Timbre::Vibraphone::vibraphone($rate),
      channels  => { left => 0.8, right => 0.2 },
  }
);
