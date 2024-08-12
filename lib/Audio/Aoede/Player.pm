use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Player {
    field $handle;

    method handle {
        return $handle;
    }

    method _set_handle ($new_handle) {
        $handle = $new_handle;
    }

}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Player - a generic player for Aoede

=head1 DESCRIPTION

This module is without much purpose as of now.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
