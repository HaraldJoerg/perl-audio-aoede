# ABSTRACT: An object representing a .sf2 SoundFont
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont {
    field %instruments;
    field @presets;
    field %samples;

    use MIDI::SoundFont;
    use aliased 'Audio::Aoede::SoundFont::Instrument' => 'AAS::Instrument';
    use aliased 'Audio::Aoede::SoundFont::Sample'     => 'AAS::Sample';

    sub from_file ($class,$path) {
        my $sf = $class->new;
        my %sf = MIDI::SoundFont::file2sf($path);
        my $file_version = $sf{ifil};
        $file_version  eq  '2.1'  or
            warn "Careful: Unknown SoundFont file version '",
            $file_version, "'\n";
        $sf->init(\%sf);
        return $sf;
    }

    method init($sf_ref) {
        %instruments = map {
            $_ => AAS::Instrument->from_hashref($sf_ref->{inst}{$_})
        } keys $sf_ref->{inst}->%*;
        for my $preset ($sf_ref->{phdr}->@*) {
            $presets[$preset->{wBank}][$preset->{wPreset}] = $preset;
        }
        %samples = map {
            $_ => AAS::Sample->new(
                achSampleName => $_,
                $sf_ref->{shdr}{$_}->%*
            )
        }
            keys $sf_ref->{shdr}->%*;
    }

    method instrument ($name) {
        return $instruments{$name};
    }

    method sample ($id) {
        return $samples{$id};
    }

    method patch_name ($bank_number,$patch_number) {
        return $presets[$bank_number][$patch_number]{achPresetName};
    }

}

1;
