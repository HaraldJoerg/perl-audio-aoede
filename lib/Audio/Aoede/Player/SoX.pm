use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Player::SoX
    :isa(Audio::Aoede::Player)
{
    use PDL;

    field $sox      :param = 'sox';
    field $rate     :param;
    field $encoding = 'signed-integer';
    field $bits     :param;
    field $channels :param;
    field %input_properties;
    field $input_buffer = 8192;
    field %output_properties;

    ADJUST {
        %input_properties = (
            type           => 'raw',
            rate           => $rate,
            encoding       => $encoding,
            bits           => $bits,
            channels       => $channels,
            'input-buffer' => $input_buffer,
        );
        %output_properties = (
            channels => $channels,
            ($^O =~ /MSWin32/ ? (type => 'waveaudio') : ()),
        );
    }

    method write_lpcm ($lpcm) {
        my %spec = $lpcm->spec;
        open (my $audio_handle,'|-',
              $sox,
              '--no-show-progress',
              _build_argument_list(%spec),
              '-', # We're going to feed STDIN
              _build_argument_list(%output_properties,
                                   channels => $spec{channels}),
#	      'sine.wav' ... we could write arbitary formats with SoX
#              'entertainer.ogg'
              '--default'
          );
        $audio_handle->autoflush(1);
        binmode $audio_handle;
        $self->_set_handle($audio_handle);
        print $audio_handle $lpcm->data;
    }


    sub _build_argument_list (%hash) {
        return map { ("--$_", $hash{$_} // ()) } keys %hash;
    }


}

1; # for whatever reason :)

__END__

=head1 NAME

Audio::Aoede::Player::SoX - SoX as a backend for Aoede sound

=head1 DESCRIPTION

This module is the interface to the SoX program which is used as the
OS and hardware abstraction layer: SoX is available on various
platform and works with various sound environments.

=head1 METHODS

=head2 C<new>

The constructor takes key/value pairs as arguments. 

=over

=item C<sox>

The path to the SoX binary.  Must be either an absolute file name, or
sitting in a directory listed in the C<PATH> environment variable.
The default is C<"sox">.

=item C<rate>

The number of samples per second.  Typical values are 44100 or
48000, as used by audio CDs and DVDs, respectively.

=item C<bits>

The number of bits per sample.  Defaults to 16.  Note that some
functions only work with this bit depth, or return sound in this bit
depth.

=item C<channels>

The number of channels.

=back

=head2 C<$s-E<gt>start>

Start SoX and open the pipe.

=head2 C<$s-E<gt>stop>

Close the pipe, which will stop SoX.

=head2 Internal methods

=head3 C<$s-E<gt>_build_argument_list(%hash)>

Convert a hash to C<--key=value> command line parameters for SoX.  A
value of undef in the hash denotes a parameter which doesn't take a
value.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
