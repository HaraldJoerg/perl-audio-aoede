use 5.032;
use Feature::Compat::Class;
use feature "signatures";
no warnings "experimental";

class Audio::Aoede::UI::Tuner {
    field @values;
    field @tuners;
    field $tuner;
    field $value = 440;
    field $inputline;

    use Prima qw( Sliders Label InputLine );

    ADJUST {
        @values = (0) x 5;

        $tuner = Prima::Widget->new(
            backColor => cl::White,
            alignment => ta::Center,
            pack => { side => 'top' },
        );
        my $label = $tuner->insert(
            Label =>
            text => 'Frequency (Hz):',
            alignment => ta::Center,
            valignment => ta::Center,
            pack => { side => 'left', fill => 'both' },
        );
        $inputline = $tuner->insert(
            InputLine =>
            pack => { side => 'left' },
            text => $value,
            onLeave => sub ($widget) { $self->set_value($widget->text) },
            onKeyDown => sub ($widget,$code,$key,@) {
                return unless $key;
                return unless ($key == kb::Enter  ||  $key == kb::Return);
                $self->set_value($widget->text);
            },
        );
        my $controls = $tuner->insert(
            Widget =>
            pack => { side => 'top', fill => 'both' },
        );
        my $mult = "\N{MULTIPLICATION SIGN}";
        my @titles = (
            "$mult 1000",
            "$mult 100",
            "$mult 10",
            "$mult 1",
            "$mult 0.1",
        );
        for my $frob (0..4) {
            push @tuners, $controls->insert(
                CircularSlider =>
                name => $titles[$frob],
                pack => { side => 'left', fill => 'both' },
                backColor => cl::White,
                min => 0,
                max => 9,
                value => 0,
                step => 1,
                autoTrack => 1,
                buttons => 0,
                scheme => ss::Thermometer,
                onChange => sub ($control,@rest) {
                    $self->_new_value($frob,$control->value);
                },
                onStringify => sub ($control,$value,$ref) {
                    $$ref = $value;# * 10**(3-$frob);
                },
                onEnter => sub ($control) {
                    $control->backColor(cl::LightGray);
                },
                onLeave => sub ($control) {
                    $control->backColor(cl::White);
                },
            )
        }
        $tuners[1]->value(4);
        $tuners[2]->value(4);
    };

    method insert_to ($parent) {
        $tuner->owner($parent);
    }

    method _new_value($index,$new) {
        if ($new == 0  and  $values[$index] == 9
            and  $index > 0) {
            if ($self->_carry_add($index-1)) {
                $values[$index] = 0;
            }
            else {
                $tuners[$index]->value($values[$index]);
            }
        }
        elsif ($new == 9  and  $values[$index] == 0
            and $index > 0) {
            if ($self->_carry_subtract($index-1)) {
                $values[$index] = 9;
            }
            else {
                $tuners[$index]->value($values[$index]);
            }
        }
        else {
            $values[$index] = $new;
        }
        $value = $self->_current_value;
    }

    method value {
        return $value;
    }

    method _carry_add ($index) {
        if ($values[$index] == 9) {
            if ($index > 0) {
                if ($self->_carry_add($index-1)) {
                    $values[$index] = 0;
                }
            }
            else {
                return 0;
            }
        }
        else {
            $values[$index]++;
        }
        $tuners[$index]->value($values[$index]);
    }

    method _carry_subtract ($index) {
        if ($values[$index] == 0) {
            if ($index > 0) {
                if ($self->_carry_subtract($index-1)) {
                    $values[$index] = 9;
                }
                else {
                    return 0;
                }
            }
        }
        else {
            $values[$index]--;
        }
        $tuners[$index]->value($values[$index]);
    }

    method _current_value () {
        return
            $values[0] * 1000 +
            $values[1] *  100 +
            $values[2] *   10 +
            $values[3] *    1 +
            $values[4] *    0.1;
    }

    method set_value ($new) {
        if ($new > 9999.9) {
            $new = 9999.9;
        }
        if ($new <= 0) {
            $new = 20; # arbitrary minimum, not yet enforced
        }
        my $formatted = sprintf "%05d",10*$new;
        for my $digit (0..4) {
            $tuners[$digit]->value(substr $formatted,$digit,1);
        }
    }
}

1;
