# ABSTRACT: Create and Analyze Sound
package Audio::Aoede 0.01;
use 5.036;
use experimental qw(for_list);
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede {
    use Carp;
    use File::Temp;
    use PDL 2.099;
    use List::Util();

    use Audio::Aoede::LPCM;
    use Audio::Aoede::Voice;
    use Audio::Aoede::Units qw( PI );
    use Audio::Aoede::Functions qw( :waves );

    field $rate     :param :reader = 44100;
    field $channels :param = 1;
    field $bits = 16;
    field $out      :param = undef;
    field $tuning   :param = 'equal';

    my $amplitude = 0.8*2**15;

    my $A;
    ADJUST {
        $A //= $self;
        # load_module is only available in 5.40, so do it the old way
        # Also, we do not yet really support other tuning systems,
        # but we accept any blessed junk which is ... rather sloppy.
        if (! builtin::blessed($tuning)) {
            my $tuning_module = "Audio::Aoede::Tuning::" . ucfirst $tuning;
            eval "use $tuning_module";
            if ($@) {
                croak "Could not use the tuning module '$tuning_module': '$@'";
            }
            $tuning = $tuning_module->new;
        }
    }


    method play ($piddle) {
        require Audio::Aoede::Player::SoX;
        my $max = max(abs $piddle);
        my $safe =  $max <= 1
            ? $piddle
            : $piddle / $max;
        my $player = Audio::Aoede::Player::SoX->new(
            rate     => $rate,
            bits     => $bits,
            channels => $channels,
            out      => $out // '--default',
        );
        $player->play_piddle(short($safe * $amplitude),$out);
    }

    # FIXME: This only works for a single channel
    method write ($samples) {
        my $data = short($samples * $amplitude);
        require Audio::Aoede::Player::SoX;
        my $player = Audio::Aoede::Player::SoX->new(
            rate     => $rate,
            bits     => $bits,
            channels => $channels,
            out      => $out // '--default',
        );
        $player->play_piddle($data,$out);
    }


    method play_roll ($path) {
        require Audio::Aoede::MusicRoll;
        my $music_roll = Audio::Aoede::MusicRoll->from_file($path);
        my @voices;
        my $n_samples = 0;
        for my $section ($music_roll->sections) {
            my $i_track = 0;
            for my $track ($section->tracks) {
                if (! $voices[$i_track]) {
                    require Audio::Aoede::Timbre::Vibraphone;
                    my $timbre = Audio::Aoede::Timbre::Vibraphone::vibraphone();
                    $voices[$i_track] =
                        Audio::Aoede::Voice->new(rate => $rate,
                                                 tuning => $tuning,
                                                 timbre => $timbre,
                                                );
                    $n_samples  and do {
                        $voices[$i_track]->add_samples(zeroes($n_samples));
                    };
                }
                $voices[$i_track]->add_notes($track,$section->bpm);
                $i_track++;
            }
            $n_samples = List::Util::max(map { $_->n_samples } @voices);
            for my $voice (@voices) {
                my $adjust = $n_samples - $voice->n_samples;
                # $adjust is small in case of rounding errors (8 1/8
                # notes can have a different number of samples than
                # one whole note).  It can also be large if the
                # current section has less tracks than the previous
                # one.  In that case, $adjust is the length of the
                # current section and will most likely consume the
                # carry completely.
                if ($adjust > 0) {
                    $voice->drain_carry($adjust);
                }
            }
        }

        my @samples = map { $_->samples } @voices;
        my $samples = sumover(pdl(@samples)->transpose);
        my @carry   = map { $_->carry // () } @voices;
        my $carry = @carry ? sumover(pdl(@carry)->transpose) : pdl([]);
        my $sum = $samples->append($carry);
        my $max = max(abs $sum);
        if ($max > 1) {
            $sum /= $max;
        }
        # now this is a crude hack
        $sum *= (1+0.05*sin(20*sequence($sum->dim(0))/$rate))/2;
        $sum = $self->apply_vibrato($sum,5,10);

        $self->write($sum);
        return;
    }

    method tremolo (%options) {
        require Audio::Aoede::Tremolo;
        return Audio::Aoede::Tremolo->new(%options);
    }

    method vibrato (%options) {
        require Audio::Aoede::Vibrato;
        return Audio::Aoede::Vibrato->new(%options);
    }

    method apply_vibrato ($samples,$frequency,$range) {
        my $n_samples = $samples->dim(0);
        my $timewarp = sequence($n_samples)
            + $range * sin(sequence($n_samples) * 2 * PI * $frequency / $rate);
        my $norm = ($n_samples-1) / $timewarp->at(-1);
        $timewarp *= $norm;
        my ($warped,$err) = interpolate($timewarp,
                                        sequence($n_samples),$samples);
        warn "We have errors: ", $err->sum  if $err->sum > 0;
        return $warped;
    }

    method play_notes (@notes) {
        require Audio::Aoede::Chord;
        require Audio::Aoede::Note;
        require Audio::Aoede::Track;
        require Audio::Aoede::Timbre::Vibraphone;
        my $track = Audio::Aoede::Track->new();
        for my ($note,$duration) (@notes) {
            $track->add_notes(
                Audio::Aoede::Chord->new(
                    notes => [ map { Audio::Aoede::Note->from_spn($_) }
                               split(/\s*\+\s*/,$note)
                           ],
                    duration => $duration,
                )
            );
        }
        my $timbre = Audio::Aoede::Timbre::Vibraphone::vibraphone();
        my $voice =  Audio::Aoede::Voice->new(rate   => $rate,
                                              tuning => $tuning,
                                              timbre => $timbre);
        $voice->add_notes($track);
        my $samples = $voice->samples->append($voice->carry);
        $self->write($samples);
    }


    method spectrum ($sound, $limit = 0) {
        use PDL::FFT;
        my $frequencies = float($sound);
        my $n_samples = $sound->dim(0);
        my $available = 0.5 * $n_samples;
        $limit *= $n_samples / $rate;
        $limit = int ($limit + 0.5);
        if (! $limit  or  $limit > $available) {
            $limit = $available;
        }
        if ($limit <= 0) {
            return undef;
        }
        realfft($frequencies);
        my $real = $frequencies->slice([0,$limit-1]);
        my $imag = $frequencies->slice([$available,$available+$limit-1]);
        return 2 * sqrt($real*$real + $imag*$imag) / $n_samples;
    }

    method read_wav ($path) {
        require Audio::Aoede::LPCM;
        my $lpcm = Audio::Aoede::LPCM->new_from_wav($path);


        my $n_samples = $lpcm->n_samples;
        my $sound = short zeroes($lpcm->channels,$n_samples);
        $sound->update_data_from($lpcm->data);

        # Now split it into the individual channels for further analysis
        my @channels = $sound->transpose->dog;
        return @channels;
    }


    method record_mono ($time) {
        require Audio::Aoede::Recorder::SoX;
        my $recorder = Audio::Aoede::Recorder::SoX->new(
            rate => $rate,
            bits => $bits,
            channels => 1
        );
        return $recorder->record_mono($time);
    }

    method server {
        require Audio::Aoede::Server;
        return Audio::Aoede::Server->new(
            rate => $rate
        )
    }


    method sine_wave () {
        return f_sine_wave($rate);
    }


    method sawtooth_wave () {
        return f_sawtooth_wave($rate);
    }


    method square_wave () {
        return f_square_wave($rate);
    }


    method noise ($color,%params) {
        require Audio::Aoede::Noise;
        $color = ucfirst $color;
        my $noise = Audio::Aoede::Noise::colored(
            $color,
            rate => $rate,
            'Audio::Aoede::Noise',
            bandwidth => $rate/2,
            %params,
        );
        return sub ($n_samples, $since = 0) {
            return $noise->next_samples($n_samples,$since);
        }
    }

    method plucked_envelope () {
        require Audio::Aoede::Envelope::ADSR;
        return sub ($frequency) {
            # We need to play around with this to find suitable values.
            # Maybe we could look it up somewhere?
            # FIXME: The envelopes can be cached... or maybe not
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => (2 / $frequency),
                decay   => (400 / $frequency),
                sustain => 0.1,
                release => (50 / $frequency),
            );
        }
    }

    sub instance ($class) {
        $A //= $class->new();
        return $A;
    }
}


1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede - the entry point to Aoede sound

=head1 SYNOPSIS

  my $A = Audio::Aoede->new();
  $A->play_roll($path);

=head1 DESCRIPTION

In case you are wondering: Aoede is the muse of voice and song in
ancient Boeotia.  I was looking for a name unlikely to collide with
anything else.

L<Audio::Aoede::Overview> shows what is in this distribution.

This module itself is the untidy catch-all for stuff which has failed
to find its place in the class taxonomy so far.  Expect its contents
to be rather volatile, and the interface unstable.  Methods not
documented here are likely to be moved elsewhere without notice.

The object of this class is meant to be (but not enforced to be) a
singleton.  It provides pragmatic defaults and easy-to-use convenience
methods.

=head1 METHODS

=over

=item C<< $aoede = Audio::Aoede->new(%params) >>

Create a new aoede object.  The keys for the C<%params> hash are:

=over

=item C<rate>

The whole suite operates at one fixed rate of sound samples per
second.  The default value is 44100, the rate used by audio CDs.

=item C<channels>

The number of audio channels.  Defaults to 1.

Right now, more than one channel is not supported by code in this
repository.

=item C<out>

The path to the output file.  If not provided (or undefined), output
is immediately sent to the default sound device.

If a path is given, then its extension is used to infer the audio
format.  Any format which is supported by your installation of SoX is
permitted.  The list of permitted formats / extensions varies between
operating systems, please consult your local documentation:
C<sox --help-format all>

C<.wav> for (Microsoft) WaveAudio files and C<.ogg> for Ogg Vorbis
compressed encoding should work everywhere.

=back

=item C<rate>

Returns the sample rate given when the object was created.

=item C<play($samples)>

Play the samples given as parameter.  The samples are normalized to
the maximum amplitude of the player, but only if the amplitude of
samples is not in the interval [-1.0,1.0].

The samples must provide the number of channels given when
constructing the object.

=item C<play_roll($path)>

Play a music roll presented as a
L<MRT file|Audio::Aoede::MusicRoll::Format>.

While this is nice and convenient, it is actually rather incomplete:
It works with one channel only, and there's a hardwired mapping of
tracks to timbres.  I have not yet found an API I like for that.

=item C<play_notes(@notes)>

Play notes given as a flat list of note names and durations.  Example:

  @notes = ('C4' => 1/4, 'E4' => 1/4, 'G4' => 1/4, 'E4+G4+C5' => 1/2);
  $A->play_notes(@notes);

Note that the "fat comma" C<< => >> is purely for decoration and ease
of reading.  This is a list, not to be used as a hash!

=item C<spectrum($samples,$limit)>

Returns a power spectrum for the PDL array given in C<$samples>.  The
second parameter C<$limit> is optional, if given, then the spectrum is
only returned up to that frequency.  Per default, the spectrum is
provided up to its maximum frequency which is equal to half the sample
rate ("Nyquist frequency").

The number of available elements in the spectrum is half of the number
of samples given if no C<$limit> is set.  If, for example, you provide
on second of samples, then you get a spectral resolution of 1Hz.  A
higher number of samples gives a better spectral resolution, but a
worse time resolution (Küpfmüllers uncertainty principle).

=back

=head1 BUGS

=over

=item There is no API for timbre declaration

We have some features to define timbre, but many of them need
functions which return functions.  This is difficult to write.  The
work on SoundFont synthesis is supposed to help to define parameters
for a declarative route to a timbre.  I do not want to drop the
Aoede-specific "sound from scratch" features like define a set of sine
functions with overtones, though.

I also have not yet found a way to declare the use of timbre in MRT
files.  MIDI uses numbers for instruments (which it calls "programs"),
SoundFont files use different names for the same number.  I might at
some time use
L<General MIDI|https://en.wikipedia.org/wiki/General_MIDI> (GM1)
as an inspiration, but I am way too lazy to define the full GM1 set.


=item The handling of the sample rate is constantly changing

I am still unsure what's the best way to define the sample rate for
the various Aoede components.  The sound generation, obviously, needs
to use a consistent sample rate which suggests it should be a global
value.  As such it is available with the L<< /C<rate> >> method.  This
value is also used when Aoede reads sound files via SoX, regardless of
the sample rate of the file itself.

However, when I<reading> sound from a source which provides raw
samples, for example from SoundFont files, then we need to respect
their metadata.  Also, some modules and methods can operate at any
sample rate, so it would make sense to pass the rate to these methods.

Currently the classes which need to operate at a fixed rate all expect
the rate to be passed as constructor parameters.  I might want to make
all these optional and, if not given, pull it from the Audio::Aoede
singleton object.  This means that this object needs to be created
explicitly before all others if you want a non-default rate.

=item The MRT player(s) need(s) cleanup

The original MRT player F<bin/mrt_play> has a hardwired timbre and
only one channel.  Lifting these restrictions is being hacked in
F<bin/mrt_xplay>, stuff I need has been simply copied into that file.
This is stalled because L</"There is no API for timbre declaration>.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024-2025 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
