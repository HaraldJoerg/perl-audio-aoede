# Abstract: An Aoede filter which does not change anything
package Audio::Aoede::Filter::Identity;
use 5.038;

use Feature::Compat::Class;

class Audio::Aoede::Filter::Identity;

use PDL;
use PDL::FFT;

method filter ($data) {
    return $data;
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Filter::Identity - A filter that does nothing

=head1 SYNOPSIS

  use Audio::Aoede::Filter::Identity;
  # Just don't.  Why would you?

=head1 DESCRIPTION

This module is used for diagnostics only - if something goes wrong
with a filter, it helps to find whether the bug is in the filter or in
the way it is used.  Replace the bad filter by identity and see what
happens.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Harald Jörg

This module is part of the L<Audio::Aoede> suite. It is free software;
you may redistribute it and/or modify it under the same terms as Perl
itself.
