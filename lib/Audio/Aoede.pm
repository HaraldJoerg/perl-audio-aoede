# ABSTRACT: Create and Analyze Sound
package Audio::Aoede 0.01;
use 5.036;
use experimental qw(for_list);
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede {
    use File::Temp;
    use PDL 2.099;
    use List::Util();

    use Audio::Aoede::LPCM;
    use Audio::Aoede::Voice;
    use Audio::Aoede::Units qw( PI );
    use Audio::Aoede::Functions qw( :waves );

    field $rate   :param = 44100;
    field $channels = 1;
    field $bits = 16;
    field $out    :param = undef;

    my $amplitude = 2**14;

    ADJUST {
        # if ($player eq 'sox') {
        #     $player = Audio::Aoede::Player::SoX->new(
        #         rate     => $rate,
        #         bits     => $bits,
        #         channels => $channels,
        #         out      => $out // '--default',
        #     );
        # }
    }

    method rate {
        return $rate;
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


    # FIXME: This only works for a single channel
    method play_samples ($samples) {
        my $max = max($samples->abs);
        if ($max > 1) {
            $samples /= $max;
        }
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
                    $voices[$i_track] =
                    Audio::Aoede::Voice->new(rate => $rate);
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

    # FIXME+FIXME: It is currently unused and also broken since tracks
    # are now objects and not array references.
    method play_notes (@notes) {
        use Audio::Aoede::Tuning::Equal qw(note2pitch);
        require Audio::Aoede::Notes; # FIXME!!!
        require Audio::Aoede::Track;
        require Audio::Aoede::Timbre::Vibraphone;
        my $track = Audio::Aoede::Track->new
            (timbre => Audio::Aoede::Timbre::Vibraphone::vibraphone($rate));
        $track->add_notes(map {
            my ($chord,$duration) = @$_;
            my @pitches = map { note2pitch($_) } @$chord;
            Audio::Aoede::Notes->new(
                duration => $duration,
                pitches =>  [map { note2pitch($_) } @$chord],
            )
        } @notes);
        my $voice =  Audio::Aoede::Voice->new(rate => $rate);
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
            'Audio::Aoede::Noise',
            bandwidth => $rate/2,
            %params,
        );
        return sub ($n_samples, $since = 0) {
            return $noise->samples($n_samples,$since);
        }
    }

    method plucked_envelope () {
        require Audio::Aoede::Envelope::ADSR;
        return sub ($frequency) {
            # We need to play around with this to find suitable values.
            # Maybe we could look it up somewhere?
            my $samples_per_period = $rate / $frequency;
            # FIXME: The envelopes can be cached... or maybe not
            return Audio::Aoede::Envelope::ADSR->new(
                attack  => int(2 * $samples_per_period),
                decay   => int(400 * $samples_per_period),
                sustain => 0.1,
                release => int(50 * $samples_per_period),
            );
        }
    }
}


1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede - the entry point to Aoede sound

=head1 SYNOPSIS

  my $aoede = Audio::Aoede->new(player => 'sox');
  $aoede->play_roll($path);

=head1 DESCRIPTION

In case you are wondering: Aoede is the muse of voice and song in
ancient Boeotia.  I was looking for a name unlikely to collide with
anything else.

This module is the untidy catch-all for stuff which has failed to find
its place in the class taxonomy so far.  Expect its contents to be
rather volatile, and the interface unstable.  Methods not documented
here are likely to be moved elsewhere without notice.

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

=item bits

The number of bits per audio sample.  Defaults to 16.

This should not even be a parameter right now because the software
only works with 16 bits.

It is very unlikely that we'll ever support 24-bit sound: The current
implementation uses L<PDL>, therefore a sample must be represented by
a data type known by PDL.  The data types of PDL are native types of
the C programming language, and C has no type with a width of 24 bits.

=item player

Per default, Aoede writes its sound output as WAV files.  I recommend
to install L<SoX|https://sourceforge.net/projects/sox/> (also
available as package C<sox> in Linux distributions).  If you have done so, you can activate this player as

   player => 'sox'

SoX can be used to play sound directly on your sound card, but also to
convert Aoede sound to a variety of sound formats.  We have no
interface for this right now, sorry.

=back

=item C<play_roll($path)>

Play a music roll presented as a
L<MRT file|Audio::Aoede::MusicRoll::Format>.

=item C<play_samples>

Play the samples given as parameter.  The samples are normalized to
the maximum amplitude of the player, but only if the amplitude of
samples is not in the interval [-1.0,1.0].

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
