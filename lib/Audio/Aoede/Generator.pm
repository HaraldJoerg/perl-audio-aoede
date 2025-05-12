package Audio::Aoede::Generator;
use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Generator;

use Carp;
use PDL;

field $function :param;


method function ($frequency) {
    return $function->($frequency)
}

1;

__END__

=head1 NAME

Audio::Aoede::Generator - A generic function generator

=head1 SYNOPSIS

  use Audio::Aoede::Generator;
  my $g = Audio::Aoede::Generator->new(
    function => sub($frequency) {
    },
  );

=head1 DESCRIPTION

This is a generic class for function generators which take a frequency
to create sources of sound.  Generators are used by
L<Audio::Aoede::Timbre>.

Use L<Audio::Aoede::Source> to create sounds where the generator does
not take a frequency.

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Harald Jörg

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

