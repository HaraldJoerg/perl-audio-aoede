# ABSTRACT: An object representing a .sf2 SoundFont preset
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont::Preset {
    field @ibags;
    field %generators;

    use aliased 'Audio::Aoede::SoundFont::Generator'  => 'AAS::Generator';

    sub from_hashref($class,$href) {
        my $preset = $class->new;
        $preset->init($href->{ibags});
    }

    method init ($ibag_ref) {
        @ibags = $ibag_ref->@*;
        return $self;
    }

    method generator ($note) {
        if ($generators{$note}) {
            return $generators{$note};
        }
        my ($sample_id,$generator);
      IBAG:
        for my $ibag (@ibags) {
            $generator = $ibag->{generators};
            my $range = $generator->{keyRange} // [0,127];
            my ($min,$max) = @$range;
            if ($note >= $min  and  $note <= $max) {
                $sample_id = $generator->{sampleID};
                defined $sample_id  and  last IBAG;
            }
        }
        $sample_id  or  die "Sorry, no sample";
        $generators{$note} = AAS::Generator->new(%$generator);
        return $generators{$note};
    }
}

1;
