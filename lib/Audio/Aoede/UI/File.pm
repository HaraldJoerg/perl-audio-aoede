# ABSTRACT: Show the "current" file in Aoede
package Audio::Aoede::UI::File;

use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::File;

use File::Spec;
use Prima qw( Dialog::FileDialog Sliders );

field $file_info;
field $parent   :param;
field $path;
field $duration = 0;
field $position;
field $pack     :param;
field $label;
field $stopwatch;
field $slider;
field $current_directory;

ADJUST {
    $file_info = $parent->insert(
        Widget =>
        pack => $pack,
        ownerBackColor => 1,
        visible => 0,
    );
    my $top = $file_info->insert (
        Widget =>
        ownerBackColor => 1,
        pack => { side => 'top' }
    );
    $label = $top->insert(
        Label =>
        text => $path // '(no file)',
        ownerBackColor => 1,
        pack => { side => 'left', },
    );
    my $position_display = $file_info->insert(
        Widget =>
        ownerBackColor => 1,
        pack => { side => 'top' },
    );
    $slider = $position_display->insert(
        Slider =>
        increment => 1,
        step => 1,
        min => 0,
        max => $duration,
        size => [600,50],
        autoTrack => 1,
        ribbonStrip => 1,
        ticks => undef,
        ownerBackColor => 1,
        pack => { side => 'left', },
        onChange => sub ($widget) { $self->slider_change($widget->value) },
    );
    $stopwatch = $position_display->insert(
        Label =>
        text => join('/',format_time(0),format_time($duration)),
        ownerBackColor => 1,
        pack => { side => 'left', padx => 20 },
    );
}


method open_file {
    my $open = Prima::Dialog::OpenDialog->new(
        filter => [
            ['Ogg vorbis sound files' => '*.ogg'],
            ['All' => '*'],
        ],
        directory => $current_directory || '.',
    );
    if ($open->execute) {
        $path = $open->fileName;
        my ($vol,$dirs,$file) = File::Spec->splitpath($path);
        {
            no warnings 'once';
            $parent->text("$::title: $file");
        }
        $current_directory = $open->directory;
        $label->text($file);
        $slider->hide;
        $file_info->visible(1);
        return $path;
    }
    else {
        return;
    }

}


method save_as {
    my $save = Prima::Dialog::SaveDialog->new(
        filter => [
            ['Ogg vorbis sound files' => '*.ogg'],
            ['All' => '*'],
        ],
        directory => $current_directory || '.',
    );
    if ($save->execute) {
        my $path = $save->fileName;
        my ($vol,$dirs,$file) = File::Spec->splitpath($path);
        $label->text($path);
        return $path;
    }
    else {
        return;
    }
}


method set_max_time ($new) {
    $slider->max($new);
    $slider->show;
    $duration = $new;
    $stopwatch->text(format_time($slider->value) . '/' .
                     format_time($duration));
}


method set_position ($new) {
    # This will trigger slider_change iff we hit a new second which in
    # turn will update the stopwatch - so the stopwatch shows only seconds
    $slider->value($new);
}


method slider_change ($value) {
    {
        # I would prefer to get rid of that function call but I have
        # no good idea how
        no warnings 'once';
        main::update_position_by_ui($value);
    }
    $stopwatch->text(format_time($value) . '/' . format_time($duration));
}


method recording {
    $label->text('Recording...');
    $file_info->visible(1);
}


sub format_time ($time) {
    return sprintf("%02d:%02.0f",int($time/60),$time % 60);
}



1;
