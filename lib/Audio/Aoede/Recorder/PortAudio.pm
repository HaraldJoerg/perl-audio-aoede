package Audio::Aoede::Recorder::PortAudio;
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
use feature 'try';
no warnings 'experimental';

class Audio::Aoede::Recorder::PortAudio
#    :isa(Audio::Aoede::Recorder)  The parent class does not yet exist
{
    use Capture::Tiny qw( capture );
    use PDL;
    use autodie;

    field $rate     :param;
    field $bits     :param; # unused / fixed to 16
    field $channels :param;
    field $in       :param = '--default'; # unused
    field %output_properties;
    field $handle :reader;


    ADJUST {
        capture {
            require Audio::PortAudio;
        };
    }

    method open_pipe {
        my $api = Audio::PortAudio::default_host_api();
        my $device = $api->default_input_device;

        $handle = $device->open_read_stream(
            {
                channel_count => $channels,
                sample_format => 'int16'
            },
            $rate,
            2048, # Arbitrary, we'll need to fiddle here
            0
        );
        my $buffer;
        return $handle;
    }


    method read_pipe ($n_samples) {
        my $data;
        $handle->read($data,$n_samples);
        my $sound = short zeroes ($channels,$n_samples);
        my $sound_ref = $sound->get_dataref;
        $$sound_ref = $data;
        $sound->upd_data;
        return $sound;
    }


    method close_pipe {
        # We suppress errors like "not a GLOB reference" and
        # "Invalid stream pointer" here.
        capture {
            $handle  and  eval { $handle->close; };
            undef $handle;
        };
    }
}

1; # for whatever reason :)

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Recorder::PortAudio - PortAudio as a backend for Aoede sound

=head1 DESCRIPTION

This module is the interface to the PortAudio program which is used as the
OS and hardware abstraction layer: PortAudio is available on various
platform and works with various sound environments.

=head1 METHODS

=head2 C<new>

The constructor takes key/value pairs as arguments.

=over

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

=head2 class method play_lpcm

=head2 C<$s-E<gt>start>

Start PortAudio and open the pipe.

=head2 C<$s-E<gt>stop>

Close the pipe, which will stop PortAudio.

=head2 C<< $s->play_piddle($piddle[,$output]) >>

Write C<$piddle> conforming to the player's specification to the
specified output path, or to the default sound device if no path is
provided.

=head2 Internal methods

=head3 C<$s-E<gt>_build_argument_list(%hash)>

Convert a hash to C<--key=value> command line parameters for PortAudio.  A
value of undef in the hash denotes a parameter which doesn't take a
value.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
