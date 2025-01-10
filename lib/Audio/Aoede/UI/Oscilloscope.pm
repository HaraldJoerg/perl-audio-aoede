# ABSTRACT: A graphical Oscilloscope for sound
package Audio::Aoede::UI::Oscilloscope;
use 5.032;
use Feature::Compat::Class;
use feature "signatures";
no warnings "experimental";

class Audio::Aoede::UI::Oscilloscope {
    field $parent    :param;
    field $size      :param  = [400,400];
    field $pack      :param;
    field $frequency :param;
    field $rate      :param;
    field $source    :param;
    field $plot;

    method set_frequency ($new_frequency) {
        $frequency = $new_frequency || 0.1;
    }

    use Prima;
    use PDL;
    use PDL::Graphics::Prima;

    ADJUST {
        $plot = $parent->insert(
            Plot =>
            color => cl::Green,
            backColor => cl::Black,
            size => $size,
            sizeMin => [50,50],
            pack => $pack,
            x => { format_tick => sub { ' ' } },
            y => { min => -1.05, # leave some margin
                   max =>  1.05,
                   format_tick => sub { ' ' },
               },
            '-data' => ds::Pair(
                sequence(200),
                zeroes(200),
                plotType => ppair::Lines,
            ),
        );
    }

    method update () {
        my $samples_per_period = $rate / $frequency;
	# Fetch two periods and find a suitable starting point
	my $data = $source->fetch_data(int(2 * $samples_per_period + 0.5));
	my $start = $data->slice([0,$samples_per_period-1])->minimum_ind;

        $plot->dataSets->{data}  =
            ds::Pair(sequence($samples_per_period),
                     $data->slice([$start,$start+$samples_per_period-1]),
                     plotType => ppair::Lines,);
        $plot->repaint;
    }

}

1;

__END__

=head1 NAME

Audio::Aoede::UI::Oscilloscope - A graphical oscilloscope

=head1 SYNOPSIS

    my $oscilloscope = Audio::Aoede::UI::Oscilloscope->new(
        parent    => $prima_widget
        frequency => $frequency,
        rate      => $rate,
        source    => $audio_server,
        size      => [400,400],
        pack      => { side => 'left', fill => 'both' },
    );

    # Later, in your animation loop, for each frame:

    $oscilloscope->update;

=head1 DESCRIPTION

This module provides a L<Prima> widget for displaying a waveform in
the style of an oscilloscope.

=head1 METHODS

=head2 C<new(%params)>

Constructs a new C<Audio::Aoede::UI::Oscilloscope> Object, and places
its user interface into the given widget.  The application is expected
to call this objects C<update> method at regular intervals.

The parameters are:

=over

=item C<parent>

The Prima widget where the oscilloscope will be shown.  At some point
I want to get rid of that bottom-up construction.

=item C<size>

An array reference providing the width and height of the oscilloscope
widget.  Defaults to C<[400,400]>.

=item C<pack>

The C<pack> parameter as needed for C<Prima> placement.

=item C<frequency>

The base frequency: How often per second the x coordinate of the
oscilloscope will start at 0.

=item C<source>

The data source which can be called to obtain new data.  Usually an
L<Audio::Aoede::Server> object.  Needs to provide methods
C<current_sample> and C<fetch_data>.

=item C<rate>

The number of samples per second provided by the data source.

=back

=head2 C<set_frequency($new_frequency)>

Sets a new frequency for the oscilloscope.

=head2 C<update()>

Fetch new data from the source, and display them.
