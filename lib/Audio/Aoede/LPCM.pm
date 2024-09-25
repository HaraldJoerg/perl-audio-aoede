use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';
use autodie;

class Audio::Aoede::LPCM 0.01 {
    field $rate     :param = 48000;
    field $encoding :param = 'signed-integer';
    field $bits     :param = 16;
    field $channels :param = 1;
    field $data     :param = undef;

    use Carp;

    sub new_from_wav ($class,$path) {
        open (my $handle,'<',$path); # autodie takes care of errors
        binmode $handle;
        my $lpcm = $class->new;
        $lpcm->read_wav($handle);
        return $lpcm;
    }


    method read_wav ($handle) {
        $handle->read($data,4);
        $data  eq  'RIFF'
            or Carp::croak("Invalid data in WAV file: '$data'");

        $handle->read($data,4);
        my $length = unpack("l",$data); # max is 2GB, so ... just slurp it
        read $handle,$data,$length;

        substr($data,0,4)  eq  'WAVE'
            or Carp::croak("Invalid data in RIFF file: '",
                           substr($data,0,4),"'\n");

        my $pos = 4;
        my ($format_tag,$bytes_per_sec,$blockalign);

        while ($pos < $length) {
            my $id     = substr($data,$pos,4);
            my $length = unpack("l",substr($data,$pos+4,4));
            $pos += 8;
            if ($id  eq  'fmt '  and  $length >= 16) {
                ($format_tag,$channels,$rate,
                 $bytes_per_sec,$blockalign,$bits) =
                     unpack("ssllss",substr($data,$pos,16));
                $format_tag  !=  1 # WAVE_FORMAT_PCM
                    and Carp::croak("We can't process non-LPCM formatted data ",
                                    "($format_tag).  Sorry.\n");
            }
            elsif ($id  eq  'data') {
                defined $format_tag
                    or Carp::croak("Invalid data: no format tag found\n");
                $data = substr($data,$pos,$length);
            }
            else {
                # We simply ignore all other chunks and tags!
            }
            $pos += $length;
        }
        $encoding = $bits == 8 ? 'unsigned-integer' : 'signed-integer';
    }


    method write_wav ($to = undef) {
        my $handle;
        if ($to) {
            open ($handle, '>', $to)
                or croak qq(Can not write to '$to': '$!');
        }
        else {
            $handle = File::Temp->new(SUFFIX => '.wav',
                                      UNLINK => 0);
            $to = "$handle";
        }
        binmode $handle;
        print $handle 'RIFF';
        my $header = 'WAVE';
        $header .= 'fmt ';
        $header .= pack('l',16);
        $header .= pack('ssllss',
                        1, # format = WAVE_FORMAT_PCM
                        $channels,
                        $rate,
                        $rate * $channels * $bits/8,
                        $channels * $bits/8,
                        $bits,
                    );
        $header .= 'data';
        print $handle pack('l',length($data) + length($header) + 4);
        print $handle $header;
        print $handle pack('l',length($data));
        print $handle $data;
        close $handle;
        return $to;
    }


    method rate {
        return $rate;
    }

    method channels {
        return $channels;
    }

    method data {
        return $data;
    }

    method set_data ($new_data) {
        $data = $new_data;
    }

    method n_samples {
        return length($data) / $channels / ($bits/8);
    }

    method spec {
        return (type     => 'raw',
                rate     => $rate,
                encoding => $encoding,
                bits     => $bits,
                channels => $channels,
            );
    }

}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::LPCM - Linear Pulse-Code Modulated Data

=head1 SYNOPSIS

  use Audio::Aoede::LPCM;
  my $sound = Audio::Aoede::LPCM->new();

=head1 DESCRIPTION

Linear pulse-code modulation (LPCM) is the simplest representation of
uncompressed sound data.  LPCM is the usual format found on audio CDs,
and used as the most common encoding format in L</WAV> files.

The raw LPCM data need a set of metadata so that they can be
processed.  Objects of this class hold these metadata together with
the LPCM data.

=head1 METHODS

=head2 Class Method C<< Audio::Aoede::LPCM->new >>

This constructs the object from the following parameters which can be
given as C<key=>$value> pairs.  The valid keys are:

=over

=item data

The raw binary data.  Must be provided, no default value.

=item rate

The number of samples per second.  Default: C<rate =E<gt> 48000>.

=item encoding

The Encoding of data.  Default: C<encoding =E<gt> 'signed-integer'>.

=item bits

The number of bits per sample point.  Default: C<bits =E<gt> 16>.

=item channels

The number of channels.  Default: C<channels =E<gt> 1>.

=back

=head2 Method C<rate>

Returns the current bit rate (samples per second).

=head2 Method C<channels>

Returns the current number of channels.

=head2 Method C<data>

Returns the raw sample data.

=head2 Method C<set_data($new_data)>

Sets C<$new_data> to be the new data.  The new data must have the same
bit rate, bits per sample and number of channels as the original one.

=head2 Method C<n_samples>

Returns the number of samples in the raw data.

=head2 Method C<spec>

Returns a hash providing the metadata of the current sample data.
The hash contains the following keys:

=over

=item bits

=item channels

=item encoding

=item rate

=item type

This key always has the value 'raw' for Audio::Aoede::LPCM objects.

=back

=head2 Class Method new_from_wav

   $lpcm = Audio::Aoede::LPCM->new_from_wav($path)

Alternative constructor: Create and return an Audio::Aoede::LPCM
object from a WAV file.

=head2 Method read_wav

This method is used internally by L</Class Method new_from_wav>.

=head2 Method write_wav

   $path = $lpcm->write_wav($to)

Write the object as a WAV file to C<$to>.  If C<$to> is missing,
undef, or false, create a temporary file.

Returns the path name of the file written.

=head1 REFERENCES

=over

=item L<WAV|https://en.wikipedia.org/wiki/WAV>

The Wikipedia article about the Waveform audio file format.

=back

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This document is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item L<Audio::Wav>

A CPAN distribution for reading and writing WAV files

=back

