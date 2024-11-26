# ABSTRACT: Real-time sound
use 5.032;
use Feature::Compat::Class;
use feature "signatures";
no warnings "experimental";

class Audio::Aoede::Server {
    field $rate     :param = 44100; # Because that's what my card does
    field $channels :param = 1;

    field %sources;
    field $start_time;
    field $current_sample; # samples before this one have been processed

    use PDL;
    use Scalar::Util qw( refaddr );
    use Time::HiRes qw( tv_interval gettimeofday );
    use constant DEBUG => '';

    use Audio::Aoede::Link;

    ADJUST {
        %sources = ();
        $self->start;
    }

    # Returns a double piddle of $n_samples samples
    method fetch_data($n_samples,$since = $current_sample) {
        my $sound = zeroes($n_samples);
        my $total_volume = 0;
        for my $source (values %sources) {
            my $volume = $source->volume;
            next unless $volume;
            my ($add,$carry) = $source->next_samples($n_samples,$since);
            $sound  += $volume * $add;
            $total_volume += $volume;
        }
        if ($total_volume < 0.01) {
            my $silence = zeroes($n_samples);
            return $silence;
        }
        else {
            if ($total_volume > 1.0) {
                $sound /= $total_volume;
            }
            return $sound;
        }
    }


    method add_sources (@new_sources) {
        @sources{ map { refaddr($_) } @new_sources} =
            map { $self->_link($_) } @new_sources;
    }


    method set_sources (@new_sources) {
        %sources = map { refaddr($_) => $self->_link($_) } @new_sources;
    }


    method remove_source ($old_source) {
        delete $sources{refaddr($old_source)};
    }


    method start_sources (@list) {
        my $current = $self->current_sample;
        @sources{ map { refadd($_) } @list } =
            map {
                $_->set_link(Audio::Aoede::Link->new(offset => $current));
            } @list;
    }

    method stop_sources (@list) {
    }

    method start {
        $start_time = [gettimeofday];
        $current_sample = 0;
    }


    method update () {
        $current_sample = int (tv_interval($start_time) * $rate + 0.5);
    }


    method current_sample {
        $self->update;
        return $current_sample;
    }


    method _link ($source) {
        $source->set_link(Audio::Aoede::Link->new(
            offset => $self->current_sample,
        ));
        return $source;
    }

}

1;

__END__

=head1 NAME

Audio::Aoede::Server - real-time sound

=head1 DESCRIPTION

This module is a helper to add real-time sound to a Perl program.  It
is, despite its name, not a standalone server: It manages the
connection and data flow to a "real" server, implemented as a simple
pipe open to SoX.

=head2 The Back-end: SoX

The actual sound (i.e. feeding your computer's sound card) is
generated by L<SoX|https://en.wikipedia.org/wiki/SoX>.  SoX is
available as a package from Linux distributions, but also available on
Windows.

SoX is also able to store sound generated by the Audio::Aoede modules
in compressed formats like OGG or MP3, which might come in handy
later.  This is not yet implemented.

SoX also has its own synthesizer, mixer and effects library, so it is
a lot of fun to play with.  We don't use these here, though.

=head1 METHODS

=head2 C<new>

The constructor takes key/value pairs as arguments.  All of them are
optional.

=over

=item C<rate>

The number of samples per second.  Defaults to 44100.

=item C<channels>

The number of channels.  Defaults to 1.

=back

=head2 C<$sound = $s-E<gt>fetch_data($n_samples,$since)>

Returns a L<PDL> object containing C<$n_samples> samples, to be played
after C<$since>.  If C<$since> is omitted, then it returns the samples
to be played after the previous call to C<fetch_data>.

The PDL object contains floating point numbers.  This makes it robust
against overflow when the sound is modified by effects, but it it
can't be played back directly without being converted appropriately.

=head2 C<$s-E<gt>add_sources(@sources)>

Add the list of sources in C<@sources> to the server.  The sources must
behave like L<Audio::Aoede::Source> objects.

=head2 C<$s-E<gt>remove_source($source)>

Remove C<$source> from the server.  Does nothing if the source was not
added before.

=head2 C<$s-E<gt>start>

Start the server.  This creates the SoX instance and starts clocking
time.

=head2 C<$s-E<gt>stop>

Stop the server.  Stop SoX, and set the server to silent.

=head2 C<$s-E<gt>update>

This is the main method to call in a loop when using the server.  The
method does its own time management, but no event management: You just
need to call it regularly without parameters.  I (haj) found it works
good enough with a time tick of 20 ms (or 50 calls per second) which I
organize with a L<Prima::Timer>, which is a timer I use for animations
in my L<Prima> programs anyway.

=head2 C<$s-E<gt>current_sample()

Return the next sample to be provided.  Used by
L<Audio::Aoede::UI::Oscilloscope> and other classes which want up to
date samples but do not need a continuous stream.
