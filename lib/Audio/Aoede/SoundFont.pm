# ABSTRACT: An object representing a .sf2 SoundFont
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::SoundFont {
    field %instruments;
    field @presets;
    field %presets;
    field %samples;
    field %generator_cache;

    use MIDI::SoundFont;
    use Audio::Aoede::SoundFont::Instrument;
    use Audio::Aoede::SoundFont::Preset;
    use Audio::Aoede::SoundFont::Sample;
    use Audio::Aoede::SoundFont::Generator;
    use Audio::Aoede::Source::SoundFont;

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
        my $inst = $sf_ref->{inst};
        %instruments = map {
            $_ => Audio::Aoede::SoundFont::Instrument->from_hashref(
                $inst->{$_}
            );
        } keys %$inst;
        for my $preset ($sf_ref->{phdr}->@*) {
            $presets[$preset->{wBank}][$preset->{wPreset}] =
                Audio::Aoede::SoundFont::Preset->from_hashref($preset);
            $presets{$preset->{wBank}}{$preset->{achPresetName}} =
                Audio::Aoede::SoundFont::Preset->from_hashref($preset);
        }
        %samples = map {
            $_ => Audio::Aoede::SoundFont::Sample->new(
                achSampleName => $_,
                $sf_ref->{shdr}{$_}->%*
            )
        }
            keys $sf_ref->{shdr}->%*;
    }

    method instrument ($name) {
        return $instruments{$name};
    }


    method patch ($bank_number,$patch_number) {
        return $presets[$bank_number][$patch_number];
    }


    method preset ($bank_number,$patch_number) {
        return $presets[$bank_number][$patch_number];
    }


    method sample_by_id ($id) {
        return $samples{$id};
    }


    method generators ($bank_number,$patch_number,$note,$velocity) {
        if (my $cached = $generator_cache{$bank_number}{$patch_number}
            {$note}{$velocity}) {
            return @$cached;
        }
        my $preset = $self->patch($bank_number,$patch_number);
        my @pbags = $preset->applicable_pbags($note,$velocity);
        my @generators = ();
      PBAG:
        for my $pbag (@pbags) {
            my $p_gens = $pbag->{generators};
            if (my $instrument_name = $p_gens->{instrument}) {
                my $i_globals;
                my $instrument = $self->instrument($instrument_name);
                my @ibags = $instrument->applicable_ibags($note,$velocity);
                next PBAG if scalar @ibags == 0;
                for my $ibag (@ibags) {
                    my $i_gens = $ibag->{generators};
                    my $sample_id = $i_gens->{sampleID};
                    if ($sample_id) {
                        my %i_globals = $i_globals ? %$i_globals : ();
                        my %instrument_generators = (%i_globals,%$i_gens);
                        my %effective_generators = _merge_generators(
                            $p_gens,
                            %instrument_generators
                        );
                        push @generators,
                            Audio::Aoede::SoundFont::Generator->new(
                                %effective_generators,
                                sfSample => $samples{$sample_id},
                                name     => $instrument_name,
                            );
                        # So, let's collect that stuff for diagnostics.
                        push @main::generators,
                            {
                                p => { %$p_gens },
                                g => { %i_globals },
                                i => { %$i_gens },
                                e => { %effective_generators },
                            };
                    }
                    else {
                        if ($i_globals) {
                            warn "Duplicate global ibag ignored";
                        }
                        else {
                            $i_globals = $i_gens;
                        }
                    }
                }
            }
        }
        $generator_cache{$bank_number}{$patch_number}{$note}{$velocity} =
            \@generators;
            return @generators;
    }


    method sources($channel,$preset,$note,$velocity,$rate) {
        my @sources;
        my @generators = $channel == 9
            ? $self->generators(128,0,$note,$velocity)
            : $self->generators(0,$preset,$note,$velocity);
        for my $generator (@generators) {
            my ($sound,$loop) = $generator->resample($note,$rate);
            my $source = Audio::Aoede::Source::SoundFont->new(
                name      => $generator->name,
                note      => $note,
                rate      => $rate,
                velocity  => $velocity,
                sound     => $sound,
                loop      => $loop,
                vol_env   => $generator->vol_env($note,$rate),
                mod_env   => $generator->mod_env($note,$rate),
                pan       => $generator->pan,
            );
            push @sources,$source;
        }
        return @sources;
    }


    my %_merge_ignore_gens = map { $_ => 1 } qw( keyRange velRange );

    sub _merge_generators ($p_gens,%i_gens) {
        my %effective_generators = %$p_gens;
        for my ($name,$value) (%i_gens) {
            next if $_merge_ignore_gens{$name};
            if (defined $effective_generators{$name}) {
                $effective_generators{$name} += $value;
            }
            else {
                $effective_generators{$name} = $value;
            }
        }
        return %effective_generators;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::SoundFont - a class representing a .sf2 SoundFont file

=head1 DESCRIPTION

L<SoundFont|https://en.wikipedia.org/wiki/SoundFont> files are what
today's MIDI synthesizers like
L<timidity|https://de.wikipedia.org/wiki/Timidity%2B%2B> use to define
how the MIDI instruments sound.

SoundFont files contain samples recorded from real instruments which
is a detour from Aoede's plan to create "sound from scratch".  But
MIDI is everywhere, and it turned out to be an interesting challenge
to process SoundFont files.

The CPAN module L<MIDI::SoundFont> parses F<.sf2> files into a Perl
data structure but does not do any processing.  This class (and the
modules below its namespace) build on that.  They convert the data
structure into Perl objects and allow a MIDI synthesizer to obtain the
correct parameters to play a certain note with a certain instrument.

The L<Audio::Aoede::Source::SoundFont> class uses this to use
SoundFont as an L<Audio::Aoede::Source>.

=head1 METHODS

Most methods in this class are considered internal and not documented
(yet).  This class has no useful standard constructor, the only way to
get a Audio::Aoede::SoundFont object is by reading a .sf2
file.

=over

=item C<< $sf = Audio::Aoede::SoundFont->from_file($path) >>

Reads the F<.sf2> file given by $path and return the SoundFont object.
Caveat: SoundFont files can be rather large.  For example, the Linux
package timidity contains a 150MB soundfont file.  Do not try to dump
the SoundFont data structure or inspect it in the Perl debugger unless
you are really really patient.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

The L<SoundFont Technical Specification|http://www.synthfont.com/sfspec24.pdf> Version 2.04, published 2002-09-10 (PDF, 69 pages)

=item *

On CPAN: L<MIDI::SoundFont> reads SoundFont files.  This module
is up for adoption.

=back

