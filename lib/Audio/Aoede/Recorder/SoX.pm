package Audio::Aoede::Recorder::SoX;
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Recorder::SoX
#    :isa(Audio::Aoede::Recorder)  The parent class does not yet exist
{
    use PDL;
    use autodie;

    use Audio::Aoede::LPCM;

    my    $sox      = 'sox';
    my    %extra_input_properties =  ($^O =~ /MSWin32/)
        ? (type => 'waveaudio')
        : ();

    field $rate     :param;
    field $encoding = 'signed-integer';
    field $bits     :param;
    field $channels :param;
    field $in       :param = '--default';
    field %input_properties;
    field %output_properties;

    ADJUST {
        %output_properties = (
            type           => 'raw',
            rate           => $rate,
            encoding       => $encoding,
            bits           => $bits,
            channels       => $channels,
        );
        %input_properties = (
            channels => $channels,
            %extra_input_properties,
        );
    }

    sub set_sox_path ($class,$path) {
        $sox = $path;
    }

    method record_mono ($time) {
        $channels = 1;
        open (my $handle,'-|',
              $sox,
              '--no-show-progress',
              '--default',
              _build_argument_list(%output_properties),
              '-',
              'trim', 0,
              sprintf("%02d:%02d", int $time/60, $time % 60)
          );
        binmode $handle;
        my $data;
        while (1) {
            my $success = read $handle, $data, 2**16, length($data);
            die $! if not defined $success;
            last if not $success;
        }
        close $handle;
        my $sound = short zeroes (length($data) / PDL::Core::howbig(short));
        my $sound_ref = $sound->get_dataref;
        $$sound_ref = $data;
        $sound->upd_data;
        return $sound;
    }


    sub _build_argument_list (%hash) {
        return map { ("--$_", $hash{$_} // ()) } keys %hash;
    }


}

1; # for whatever reason :)

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Recorder::SoX - SoX as a backend for Aoede sound

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

   $path = Audio::Aoede::Recorder::Sox->play_lpcm($lpcm,$to)

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
