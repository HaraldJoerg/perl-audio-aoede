# ABSTRACT: An Aoede GUI for ADSR envelopes
package Audio::Aoede::UI::Envelope;
use 5.032;
use Feature::Compat::Class;
use feature "signatures";
no warnings "experimental";

class Audio::Aoede::UI::Envelope {
    use Prima qw( InputLine );
    field $trigger :param;
    field $widget;
    field %adsr = (
        attack => 0,
        decay  => 0,
        sustain => 1,
        release => 0,
    );

    # This should eventually go into a role
    method insert_to ($parent) {
        $widget->owner($parent);
        $widget->set(
            onChange => sub { $trigger->(%adsr) },
        )
    }

    ADJUST {
        $widget = Prima::Widget->new(
            pack => {side => 'top'},
        );
        for my $property (qw (Attack Decay Sustain Release) ) {
            my $property_widget = $widget->insert(
                Widget =>
                pack => {side => 'top'},
            );
            my $property_label = $property_widget->insert(
                Label =>
                pack => { side => 'left' },
                text => "~$property",
            );
            my $property_input = $property_widget->insert(
                InputLine =>
                pack => { side => 'left' },
                alignment => ta::Right,
                text => $adsr{lc $property},
                onChange => sub ($p_widget) {
                    $adsr{lc $property} = 0 + ($p_widget->text || 0);
                    $widget->notify('Change');
                },
            );
            $property_label->focusLink($property_input);
        }
    }


    method adsr () {
        return %adsr;
    }
}

1;
