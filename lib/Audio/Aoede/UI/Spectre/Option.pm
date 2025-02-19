# ABSTRACT: A single option for Aoede's audio spectrum viewer UI
package Audio::Aoede::UI::Spectre::Option;
use 5.038;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::UI::Spectre::Option;

use Prima;

field $label  :param;
field $field  :param;
field $units  :param = undef;
field $parent :param;
field @row;

ADJUST {
    @row = (
        $parent->insert(
            Label =>
            text => $label,
        ),
        (builtin::blessed $field ?
         $field
         :
         $parent->insert(
             @$field,
         ),
        ),
        (defined $units ?
         $parent->insert(
             Label =>
             text => $units,
         )
         :
         ()
        ),
    );
    $parent->gridConfigure($row[0] => column => 0, sticky => 'e',);
    if ($#row == 1) {
        $parent->gridConfigure($row[1] => column => 1, sticky => 'w',
                           colspan => 2);
    }
    else {
        $parent->gridConfigure($row[1] => column => 1, sticky => 'w',);
        $parent->gridConfigure($row[2] => column => 2, sticky => 'w',);
    }
}


method set_row ($row) {
    for (@row) {
        $parent->gridConfigure($_ => row => $row);
    }
}


method enable () {
    for my $cell (@row) {
        $cell->enabled(1);
    }
}


method disable () {
    for my $cell (@row) {
        $cell->enabled(0);
    }
}

1;
