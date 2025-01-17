# ABSTRACT: Use PortAudio as an Aoede player backend
package Audio::Aoede::Player::PortAudio;
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Player::PortAudio
    :isa(Audio::Aoede::Player)
{
    use Capture::Tiny qw( capture );
    use PDL;
    use autodie;

    ADJUST {
        capture {
            require Audio::PortAudio;
        };
    }

    my $amplitude = 2**14-1;

    field $rate     :param;
    field $bits     :param; # ignored anyway
    field $channels :param;
    field $out      :param = undef; # ignored as well for this player

    # LPCM as input contains the metadata we need, so we don't need to
    # create a player object in advance.
    # In this method, $handle is *not* the object's field, but I fail
    # to come up with a better name.

    # NOTE: This is a class method, it does not need to keep any state
    # in an object.  All required input is contained in the LPCM
    # object.
    sub play_lpcm ($class, $lpcm, $to = undef) {
        die "Not yet implemented for PortAudio"; # FIXME
        $to //= '--default'; # we don't have that in signatures yet
        my %spec = $lpcm->spec;
        my $handle = _open_pipe(
            \%spec,
            {
                channels => $spec{channels}
            },
            $to // '--default',
        );
        print $handle $lpcm->data;
        close $handle;
        return $to;
    }

    # A sound piddle does not contain the metadata we need to build
    # the PortAudio parameter lists, right now we require that a player
    # object is built in advance which contains these.  We might
    # convert it into a class method which accepts input and output
    # specs similar to LPCM objects.  But then, we might not, because
    # we'd need to validate the specs.
    method play_piddle ($piddle,$to = undef) {
        my $handle = _open_pipe($to,$rate,$channels);
        print $handle ($piddle->get_dataref->$*);
        close $handle;
    }


    method open_pipe () {
        capture {
            $self->_set_handle(_open_pipe($out,$rate,$channels));
        };
    }


    method close_pipe () {
        # We suppress errors like "not a GLOB reference" and
        # "Invalid stream pointe" here.
        $self->handle  and  eval { $self->handle->close; };
    }


    method start {
        $self->open_pipe ();
        $self->done_to($self->source->current_sample);
    }


    method stop {
        $self->update;
        capture {
            $self->handle->close;
            $self->_set_handle(undef)
        };
    }


    method send_piddle ($piddle) {
        $self->handle->write($piddle->get_dataref->$*);
    }


    method update () {
        my $todo = $self->todo();
        if (! $self->silent) {
            my $source = $self->source;
            my $data = $source->fetch_data($todo,$self->next_sample);
            my $sound = short($data * $amplitude);
            $self->send_piddle($sound);
        }
        else {
            $self->send_piddle(zeroes short,$todo);
        }
        $self->done($todo);
    }



    sub _open_pipe ($to,$rate,$channels) {
        my $api = Audio::PortAudio::default_host_api();
        my $device = $api->default_output_device;
        $to //= 'alsa'; # FIXME: In the future this goes in the signature
        my $stream = $device->open_write_stream(
            {
                channel_count => $channels,
                sample_format => 'int16',
            },
            $rate,
            4096, # We'll deal with that later
        );
        return $stream;
    }
}

1; # for whatever reason :)

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Player::PortAudio - PortAudio as a backend for Aoede sound

=head1 DESCRIPTION

This module is the interface to the PortAudio program which is used as the
OS and hardware abstraction layer: PortAudio is available on various
platform and works with various sound environments.

=head1 METHODS

=head2 C<new>

The constructor takes key/value pairs as arguments.

=over

=item C<PortAudio>

The path to the PortAudio binary.  Must be either an absolute file name, or
sitting in a directory listed in the C<PATH> environment variable.
The default is C<"PortAudio">.

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

   $path = Audio::Aoede::Player::PortAudio->play_lpcm($lpcm,$to)

Send the contents of the L<Audio::Aoede::LPCM> object C<$lpcm> to
C<$to>, using the specification of the LPCM object.  The file format
of C<$to> is deduced by PortAudio from the extension of file name.  If
C<$to> is not provided, uses the default output channel of so which is
the default sound card.

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
