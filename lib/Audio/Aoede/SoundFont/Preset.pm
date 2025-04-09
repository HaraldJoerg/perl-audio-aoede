# ABSTRACT: An object representing a .sf2 SoundFont preset
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont::Preset {
    # The first three fields are mainly for diagnostics
    field $achPresetName :param;
    field $wBank         :param;
    field $wPreset       :param;
    # The pbags (not yet objects) is where the fun starts
    field $pbags         :param;
    field @pbags;


    sub from_hashref($class,$href) {
        return $class->new(%$href);
    }


    ADJUST {
        @pbags = @$pbags;
        undef $pbags;
    }


    method name {
        return $achPresetName;
    }

    method applicable_pbags ($note,$velocity) {
        my @applicable_pbags;
        my $generator;
      PBAG:
        for my $pbag (@pbags) {
            $generator = $pbag->{generators};
            if (my $vel_range = $generator->{velRange}) {
                next PBAG if ($velocity < $vel_range->[0]);
                next PBAG if ($velocity > $vel_range->[1]);
            }
            if (my $key_range = $generator->{keyRange}) {
                next PBAG if ($note < $key_range->[0]);
                next PBAG if ($note > $key_range->[1]);
            }
            push @applicable_pbags,$pbag;
        }
        return @applicable_pbags;
    }
}

1;
