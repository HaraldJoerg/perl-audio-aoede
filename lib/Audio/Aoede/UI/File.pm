# ABSTRACT: Show the "current" file in Aoede
package Audio::Aoede::UI::File;

use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::File;

use File::Spec;
use Prima qw( Dialog::FileDialog Sliders );
use Audio::Aoede::File;
use Audio::Aoede::Functions qw( confine );

field $file_info;
field $parent   :param;
field $path;
field $position;
field $pack     :param;
field $label;
field $stopwatch;
field $stepsize = 0;
field $slider;
field $current_directory;
field $current_file;

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
        text => '(no file)',
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
        size => [600,50],
        autoTrack => 0,
        ribbonStrip => 1,
        ticks => undef,
        ownerBackColor => 1,
        pack => { side => 'left', },
        onTrack => sub ($widget) { $self->slider_change($widget->value) },
        onKeyDown => sub ($widget,$code,$key,@rest) {
            if ($key  ==  kb::Left) {
                my $new = $current_file->increment_position(-10**$stepsize);
                $widget->value($new);
                $stopwatch->text(format_time($new) . '/' .
                                 format_time($current_file->duration));
                main::run_current_spectrum();
                $widget->clear_event;
            }
            elsif ($key  ==  kb::Right) {
                my $new = $current_file->increment_position(10**$stepsize);
                $widget->value($new);
                $stopwatch->text(format_time($new) . '/' .
                                 format_time($current_file->duration));
                main::run_current_spectrum();
                $widget->clear_event;
            }

        },
    );
    $stopwatch = $position_display->insert(
        Label =>
        text => join('/',format_time(0),format_time(0)),
        ownerBackColor => 1,
        pack => { side => 'left', padx => 20 },
    );
    $position_display->insert(
        Label =>
        text => "Step width:",
        pack => { side => 'left' },
    );
    my $step_label = $position_display->insert(
        Label =>
        text => 10**$stepsize,
        pack => { side => 'left' },
    );
    $position_display->insert(
        Label =>
        text => "s",
        pack => { side => 'left' },
    );
    $position_display->insert(
        AltSpinButton =>
        min  => -2, max => 0,
        editClass => 'Prima::Label',
        value => $stepsize,
        pack => { side => 'left', padx => 20 },
        onIncrement => sub ($widget,$delta) {
            $stepsize = confine($stepsize+$delta,-2,1);
            $step_label->text(10**$stepsize);
        }
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
        $slider->hide; # ...until the duration is available
        $file_info->visible(1);
        $current_directory = $open->directory;
        return $open->fileName;
    }
    else {
        return;
    }
}


method set_label ($file) {
    $label->text($file);
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


method set_duration ($new) {
    $slider->max($new);
    $slider->show;
    $stopwatch->text(format_time($slider->value) . '/' .
                     format_time($new));
}


method set_position ($new) {
    $slider->value(confine($new,0,$current_file->duration));
    $stopwatch->text(format_time($new) . '/' .
                     format_time($current_file->duration));
}


method update_position () {
    $slider->value($current_file->position);
    $stopwatch->text(format_time($current_file->position) . '/' .
                     format_time($current_file->duration));
}


method set_current_file ($new) {
    $current_file = $new;
    $stopwatch->text(format_time($current_file->position) . '/' .
                     format_time($current_file->duration));
}


method slider_change ($value) {
    if ($value  !=  $current_file->position) {
        $current_file->set_position($value);
        $stopwatch->text(format_time($value) . '/' .
                         format_time($current_file->duration));
        main::run_current_spectrum();
    }
}


method recording {
    $label->text('Recording...');
    $file_info->visible(1);
}


sub format_time ($time) {
    my $minutes = int($time/60);
    return sprintf("%02d:%05.2f",$minutes,$time-60*$minutes);
}



1;
