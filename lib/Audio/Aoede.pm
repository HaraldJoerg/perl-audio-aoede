# ABSTRACT: Create and Analyze Sound
package Audio::Aoede 0.01;
use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede {
    use File::Temp;
    use PDL;

    use Audio::Aoede::LPCM;
    use Audio::Aoede::Player::WAV;
    use Audio::Aoede::Player::SoX;
    use Audio::Aoede::Voice;

    field $rate :param = 44100;
    field $channels = 1;
    field $bits = 16;
    field $samples;
    field @voices;
    field $player :param = Audio::Aoede::Player::WAV->new;

    my $amplitude = 2**14;

    ADJUST {
        if ($player eq 'sox') {
            $player = Audio::Aoede::Player::SoX->new(
                rate     => $rate,
                bits     => $bits,
                channels => $channels,
            );
        }
    }

    method player {
        return $player;
    }

    method write_piddle ($piddle,$out = undef) {
        $out //= '--default';
        $player->write_piddle(short($piddle * $amplitude),$out);
    }

    # FIXME: This only works for a single channel
    method write (@voices) {
        my @samples = map { $_->samples } @voices;
        my $sum = sumover(pdl(@samples)->transpose);
        my $max = max($sum);
        if ($max > 1) {
            $sum /= $max;
        }
        my $data = short($sum * $amplitude);
        $player->write_piddle($data);
    }

    method write_old (@voices) {
        my @samples = map { $_->samples } @voices;
        my $sum = sumover(pdl(@samples)->transpose);
        my $max = max($sum);
        if ($max > 1) {
            $sum /= $max;
        }
        my $data = short($sum * $amplitude);
        my $lpcm = Audio::Aoede::LPCM->new(
            rate     => $rate,
            bits     => $bits,
            encoding => 'signed-integer',
            channels => $channels,
            data     => $data->get_dataref->$*,
        );
        $player->write_lpcm($lpcm);
    }

    # FIXME: This only works for a single channel
    method write_samples ($samples) {
        my $max = max($samples->abs);
        if ($max > 1) {
            $samples /= $max;
        }
        my $data = short($samples * $amplitude);
        $player->write_piddle($data);
    }

    method write_samples_old ($samples) {
        my $max = max($samples->abs);
        if ($max > 1) {
            $samples /= $max;
        }
        my $data = short($samples * $amplitude);
        my $lpcm = Audio::Aoede::LPCM->new(
            rate     => $rate,
            bits     => $bits,
            encoding => 'signed-integer',
            channels => $channels,
            data     => $data->get_dataref->$*,
        );
        $player->write_lpcm($lpcm);
    }
    method play_roll ($path) {
        require Audio::Aoede::MusicRoll;
        my $music_roll = Audio::Aoede::MusicRoll->from_file($path);
        my @voices;
        for my $section ($music_roll->sections) {
            my $i_track = 0;
            Audio::Aoede::Units::set_bpm($section->bpm);
            for my $track ($section->tracks) {
                $voices[$i_track] //=
                    Audio::Aoede::Voice->new(
                        function          => sawtooth_wave(),
                        envelope_function => plucked_envelope(),
                    );
                $voices[$i_track]->add_notes(@$track);
                $i_track++;
            }
        }
        $self->write(@voices);
        return;
    }


    sub spectrum ($class, $sound, $rate = 44100, $limit = 0) {
        use PDL::FFT;
        my $frequencies = float($sound);
        my $n_samples = $sound->dim(0);
        my $available = 0.5 * $n_samples;
        $limit *= $n_samples / $rate;
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
}

use Exporter 'import';
our @EXPORT_OK = qw( sine_wave );

use PDL;
use Audio::Aoede::Units qw( PI rate );

sub sine_wave () {
    return sub ($n_samples, $frequency, $since = 0) {
        my $samples_per_period = rate() / $frequency;
        my $norm = 2 * PI() / $samples_per_period;
        $since -= int ($since/$samples_per_period);
        my $phase = (sequence($n_samples) + $since) * $norm;
        my $samples = sin($phase);
        return $samples;
    }
}

sub sawtooth_wave () {
    return sub ($n_samples, $frequency, $since = 0) {
        my $total_periods      = $since * $frequency / rate();
        my $samples_per_period = rate() / $frequency;
        my $partial_period     = $total_periods - int($total_periods);
        my $phase              = sequence($n_samples) / $samples_per_period;
        $phase                 += $partial_period;
        $phase                 -= long $phase;
        $phase                 *= 2;
        $phase                 -= 1;
        return $phase;
    }
}

sub plucked_envelope () {
    require Audio::Aoede::Envelope::ADSR;
    return sub ($frequency) {
        # We need to play around with this to find suitable values.
        # Maybe we could look it up somewhere?
        my $samples_per_period = rate() / $frequency;
        # FIXME: The envelopes can be cached
        return Audio::Aoede::Envelope::ADSR->new(
            attack  => int(2 * $samples_per_period),
            decay   => 3000 * sqrt($samples_per_period),
            sustain => 0.0,
            release => int(5 * $samples_per_period),
        );
    }
}

1;

__END__

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
