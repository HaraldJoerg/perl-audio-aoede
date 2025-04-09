# ABSTRACT: An object representing a .sf2 SoundFont instrument
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont::Instrument {
    field $ibags :param;
    field @ibags;


    sub from_hashref($class,$href) {
        my $instrument = $class->new(%$href);
    }


    ADJUST {
        @ibags = @$ibags;
        undef $ibags;
    }


    method applicable_ibags ($note,$velocity) {
        my @applicable_ibags;
        my $generator;
      IBAG:
        for my $ibag (@ibags) {
            $generator = $ibag->{generators};
            if (my $vel_range = $generator->{velRange}) {
                next IBAG if ($velocity < $vel_range->[0]);
                next IBAG if ($velocity > $vel_range->[1]);
            }
            if (my $key_range = $generator->{keyRange}) {
                next IBAG if ($note < $key_range->[0]);
                next IBAG if ($note > $key_range->[1]);
            }
            push @applicable_ibags,$ibag;
        }
        return @applicable_ibags;
    }
}

1;
