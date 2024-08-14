# ABSTRACT: Creating Noise in Various Colors
use 5.032;
package Audio::Aoede::Noise 0.01;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

# Configuration, somewhat arbitrary
my $bandwidth = 22050;

# Preparing our random source.  This will be re-used over and over, so
# ... our noise is not cryptographically secure.  We don't care.
use PDL;
use PDL::Constants qw(PI);
my $D_random  = random($bandwidth) * (2 * PI);
my $D_cos     = cos($D_random);
my $D_sin     = sin($D_random);

class Audio::Aoede::Noise {
    use PDL;
    use PDL::FFT;
    use List::Util (); # imports collide with PDL

    field $min_f :param = 20;
    field $max_f :param = $bandwidth;
    field $Data;
    field $current = 0;

    ADJUST {
        $self->init();
    }

    method set_min_f ($new_min_f) {
        $min_f = $new_min_f;
        $self->init;
        return $self;
    }

    method set_max_f ($new_max_f) {
        $max_f = $new_max_f;
        $self->init;
        return $self;
    }

    method init () {
        $min_f >= 1              or  $min_f = 1;
        $max_f <= $bandwidth     or  $max_f = $bandwidth;
        $max_f >  $min_f         or  $max_f = $min_f + 1;
	$min_f = int($min_f + 0.5);
	$max_f = int($max_f + 0.5);
        my $real_slice = [$min_f-1,$max_f-1];
        my $imag_slice = [$bandwidth+$min_f-1,$bandwidth+$max_f-1];
        my $D_spectrum = zeroes(2*$bandwidth);
        $D_spectrum->slice($real_slice) += $self->_real($min_f,$max_f);
        $D_spectrum->slice($imag_slice) += $self->_imag($min_f,$max_f);
        $Data = $D_spectrum->copy;
        $Data->realifft;
        # Normalize to [-1,1]
        $Data /= $Data->abs->max;
    }

    method samples ($n_samples,$start_sample = 0) {
	my $packet_size = 2 * $bandwidth;
	$start_sample = int $start_sample;
	$current = $start_sample % $packet_size;
	my $result;
	if ($current + $n_samples < $packet_size) {
	    $result = $Data->slice([$current,$current+$n_samples-1]);
	}
	elsif ($current + $n_samples == $packet_size) {
	    $result = $Data->slice([$current,$packet_size-1]);
	}
	else {
	    # wraparound needed (or just too many samples required)
	    $result = $Data->slice([$current,$packet_size-1]);
	    $n_samples -= ($packet_size - $current);

	    my $full = int($n_samples / $packet_size);
	    my $part = $n_samples - $full*$packet_size; # % $packet_size;
	    for (0..$full-1) {
		$result = $result->append($Data);
	    }
	    if ($part) {
		$result = $result->append($Data->slice([0,$part-1]));
	    }
	}
	$result = $result->copy; # don't clobber $Data
	return $result;
    }

    sub colored {
        my $derived = shift;
        my $class   = shift;
        return ($class . '::' . $derived)->new(@_);
    }

    sub white  { return colored('White', @_); }
    sub pink   { return colored('Pink',  @_); }
    sub brown  { return colored('Brown', @_); }
    sub blue   { return colored('Blue',  @_); }
    sub violet { return colored('Violet',@_); }
    sub gaussian { shift; return Audio::Aoede::Noise::Gaussian->new(@_); }

    method lpcm ($samples = $Data) {
        use Audio::Aoede::LPCM;
        my $scaled_sound = short($samples);
        return Audio::Aoede::LPCM->new(
            rate     => 44100,
            encoding => 'signed-integer',
            bits     => 16,
            channels => 1,
            data     => $scaled_sound->get_dataref->$*,
        )
    }

    method data {
        return $Data;
    }
}

class Audio::Aoede::Noise::White :isa(Audio::Aoede::Noise) {
    use PDL;
    method _real ($min,$max) {
        return $D_cos->slice([$min-1,$max-1]);
    }
    method _imag ($min,$max) {
        return $D_sin->slice([$min-1,$max-1]);
    }
}


class Audio::Aoede::Noise::Brown :isa(Audio::Aoede::Noise) {
    use PDL;
    method _real ($min,$max) {
        my $factor = slice(sequence($max)+1,[$min-1,$max-1]);
        return $D_cos->slice([$min-1,$max-1]) / $factor;
    }
    method _imag ($min,$max) {
        my $factor = slice(sequence($max)+1,[$min-1,$max-1]);
        return $D_sin->slice([$min-1,$max-1]) / $factor;
    }
}

class Audio::Aoede::Noise::Pink :isa(Audio::Aoede::Noise) {
    use PDL;
    method _real ($min,$max) {
        my $factor = slice(sequence($max)+1,[$min-1,$max-1]);
        return $D_cos->slice([$min-1,$max-1]) / sqrt($factor);
    }
    method _imag ($min,$max) {
        my $factor = slice(sequence($max)+1,[$min-1,$max-1]);
        return $D_sin->slice([$min-1,$max-1]) / sqrt($factor);
    }
}

class Audio::Aoede::Noise::Blue :isa(Audio::Aoede::Noise) {
    use PDL;
    method _real ($min,$max) {
        my $factor = slice(sequence($max)+1,[$min-1,$max-1]);
        return $D_cos->slice([$min-1,$max-1]) * sqrt($factor);
    }
    method _imag ($min,$max) {
        my $factor = slice(sequence($max)+1,[$min-1,$max-1]);
        return $D_sin->slice([$min-1,$max-1]) * sqrt($factor);
    }
}

class Audio::Aoede::Noise::Violet :isa(Audio::Aoede::Noise) {
    use PDL;
    method _real ($min,$max) {
        my $factor = slice(sequence($max)+1,[$min-1,$max-1]);
        return $D_cos->slice([$min-1,$max-1]) * $factor;
    }
    method _imag ($min,$max) {
        my $factor = slice(sequence($max)+1,[$min-1,$max-1]);
        return $D_sin->slice([$min-1,$max-1]) * $factor;
    }
}

class Audio::Aoede::Noise::Gaussian :isa(Audio::Aoede::Noise) {
    use PDL;
    field $frequency :param;
    field $width     :param;
    field $slice;
    ADJUST {
	$slice = [19,$bandwidth-1];
    }

    method factor {
	my $Df = sequence($bandwidth)->slice([19,$bandwidth-1]);
	my $De = log($Df/$frequency);
	$De *= $De;
	return exp($De/$width);
    }
    method _real {
	return $D_sin->slice([19,$bandwidth-1]) / $self->factor();
    }
    method _imag {
	return $D_cos->slice([19,$bandwidth-1]) / $self->factor();
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Noise - Creating Noise in Various Colors

=head1 SYNOPSIS

  use Audio::Aoede::Noise;
  my $white_noise = Audio::Aoede::Noise->white;
  $player->play($white_noise->lpcm);
  $server->add_voice($white_noise);

=head1 DESCRIPTION

This class provides sources of noise which can be used by other
modules of the L<Audio::Aoede> suite.  According to Wikipedia, noise
is an unwanted acoustic phenomenon, so why would you I<want> to use this
module?

Ok, for a start, the noise offered by this module isn't just I<any>
noise.  It provides noises with well-defined frequency distributions.
These noises are traditionally named after colors, this module follows
that convention.  The Audio::Aoede::Noise objects are created by
custom constructors whose name is the corresponding color:

  $white_noise = Audio::Aoede::Noise->white;
  $pink_noise  = Audio::Aoede::Noise->pink;

and so forth.  See the following section for the list of available
"colors".

Each noise can be created with two optional named parameters C<min_f>
and C<max_f>.  The noise contains frequencies between those two, the
defaults are 20 and 22050.

The noise provided by this module is created by defining the desired
spectrum as a PDL vector, and then applying a reverse fourier
transformation to get into the time domain.

=head1 METHODS

=head2 Constructors

The constructors must be called as class method like this:

  $noise = Audio::Aoede::Noise->white(%options);

The following options are available:

=over

=item min_f

The minimum frequency present in this noise in Hz.  Defaults to 20.

=item max_f

The maximum frequency present in this noise in Hz.  Defaults to 22050.

=back

=head3 C<white>

Creates a source of white noise where the signal has the same power
for every frequency.

=head3 C<pink>

Creates a source of pink noise where the signal density is inversely
proportional to the frequency.

=head3 C<brown>

Creates a source of brown noise where the signal density is inversely
proportional to the square of the frequency.

=head3 C<blue>

Creates a source of blue noise (also called azure noise) where the
power density is proportional to the frequency.

=head3 C<violet>

Creates a source of violet noise (also called purple noise) where the
power density is proportional to the square of the frequency.

=head2 Using the Noise Sources

=head3 C<lpcm>

Returns linear pulse-code modulated data as a L<Audio::Aoede::LPCM>
object, covering one second of noise.  The noise is encoded as a
single channel of signed 16-bit integers with a rate of 44100 samples
per second.

=head3 C<data>

Returns the raw L<PDL> object for one second of noise, without any
metadata.

=head3 C<samples($n_samples,$since)>

Return the next C<$n_samples> samples of noise, beginning with
C<$since>.  This is the interface required by L<Audio::Aoede::Voice>.

=head1 AUTHOR

Harald Jörg, <haj@posteo.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Harald Jörg

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

