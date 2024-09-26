use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Player::SoX
    :isa(Audio::Aoede::Player)
{
    use PDL;
    use autodie;

    my    $sox      = 'sox';
    my    %extra_output_properties =  ($^O =~ /MSWin32/)
        ? (type => 'waveaudio')
        : ();


    field $rate     :param;
    field $encoding = 'signed-integer';
    field $bits     :param;
    field $channels :param;
    field $out      :param = '--default';
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
            %extra_output_properties,
        );
    }

    sub set_sox_path ($class,$path) {
        $sox = $path;
    }

    # LPCM as input contains the metadata we need, so we don't need to
    # create a player object in advance.
    # In this method, $handle is *not* the object's field, but I fail
    # to come up with a better name.
    sub play_lpcm ($class, $lpcm, $to = undef) {
        $to //= '--default'; # we don't have that in signatures yet
        my %spec = $lpcm->spec;
        open (my $handle,'|-',
              $sox,
              '--no-show-progress',
              _build_argument_list(%spec),
              '-', # We're going to feed STDIN
              _build_argument_list(%extra_output_properties,
                                   channels => $spec{channels}),
              $to,
          );
        $handle->autoflush(1);
        binmode $handle;
        print $handle $lpcm->data;
        close $handle;
        return $to;
    }

    method play_piddle ($piddle,$to = undef) {
        $to //= $out;
        open (my $handle,'|-',
              $sox,
              '--no-show-progress',
              _build_argument_list(%input_properties),
              '-', # We're going to feed STDIN
              _build_argument_list(%output_properties),
              $to
          );
        $handle->autoflush(1);
        binmode $handle;
        $self->_set_handle($handle);
        print $handle ($piddle->get_dataref->$*);
        close $handle;
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

=head2 class method play_lpcm

   $path = Audio::Aoede::Player::Sox->play_lpcm($lpcm,$to)

Send the contents of the L<Audio::Aoede::LPCM> object C<$lpcm> to
C<$to>, using the specification of the LPCM object.  The file format
of C<$to> is deduced by sox from the extension of file name.  If
C<$to> is not provided, uses the default output channel of so which is
the default sound card.

=head2 C<$s-E<gt>start>

Start SoX and open the pipe.

=head2 C<$s-E<gt>stop>

Close the pipe, which will stop SoX.

=head2 C<< $s->play_piddle($piddle[,$output]) >>

Write C<$piddle> conforming to the player's specification to the
specified output path, or to the default sound device if no path is
provided.

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
