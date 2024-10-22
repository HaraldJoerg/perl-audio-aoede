use 5.032;
use Feature::Compat::Class;
use feature "signatures";
no warnings "experimental";

class Audio::Aoede::UI::Register {
    use Prima;
    field $stop_line;
    field @volumes;
    field $n_stops        :param = 50;
    field $stops_per_line :param = 25;
    field $i_stop                = 0;
    field $widget;
    field $trigger = sub { };

    ADJUST {
        @volumes = (0) x ($n_stops + 1); # 1-based array
        $volumes[1] = 100;
        $widget = Prima::Widget->new(
            backColor => cl::White,
            pack => { side => 'top', fill => 'both' },
        );
        my $label = $widget->insert(
            Label =>
            text => "Add harmonics",
            backColor => cl::White,
            alignment => ta::Center,
            pack => { side => 'top', fill => 'both' },
        );

        my @stops = map {
            $self->stop(
                label  => $_,
                value_ref => \$volumes[$_],
            )
        } (1..$n_stops)
    }

    method stop (%stop_params) {
        if (! ($i_stop++ % $stops_per_line)) {
            $stop_line = $widget->insert(
                Widget =>
                pack => { side => 'top', fill => 'both'},
            );
        }
        return Audio::Aoede::UI::Register::Stop->new(
            %stop_params,
            parent => $stop_line,
        );
    }

    method volumes {
        return map { $_ / 100.0 } @volumes;
    }

    method insert_to ($parent) {
        $widget->owner($parent);
    }


    method set_trigger ($coderef) {
        $widget->onChange($coderef);
    }
}

class Audio::Aoede::UI::Register::Stop {
    field $parent    :param;
    field $label     :param;
    field $value_ref :param;

    use Prima qw(Label Sliders InputLine);

    ADJUST {
        my $value_display;
        my $container = $parent->insert(
            Widget =>
            backColor => cl::White,
            pack => { side => 'left', fill => 'both' },
        );
        $container->insert(
            Label =>
            text => $label,
            alignment => ta::Center,
            pack => { side => 'top', fill => 'both' }
        );
        my $slider_size = [30,100];
        my $slider = $container->insert(
            Slider =>
            size => $slider_size,
            vertical => 1,
            backColor => cl::White,
            color => cl::White,
            pack => { side => 'top', fill => 'both' },
            value => $$value_ref,
            ribbonStrip => 1,
            autoTrack => 1,
            increment => 1,
            min => 0,
            max => 100,
            scheme => ss::Axis,
            onChange => sub ($widget) {
                $$value_ref = $widget->value;
                $value_display->text($widget->value);
                $parent->owner->notify('Change');
            },
        );
        $value_display = $container->insert(
            InputLine =>
            size => [40,30],
            alignment => ta::Right,
            borderWidth => 0,
            text => scalar $slider->value,
            insertMode => 0,
            valignment => ta::Middle,
            pack => { side => 'top', fill => 'none' },
            onChange => sub ($widget,@) {
                $slider->value($widget->text || 0);
            }
            ,
            onValidate => sub ($widget,$textref) {
                $$textref =~ s/\D//g;
                if ($$textref > $slider->max) {
                    $$textref = $slider->max;
                }
            }
        );
    }
}

1;
