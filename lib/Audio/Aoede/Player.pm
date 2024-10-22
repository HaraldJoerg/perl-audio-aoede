use 5.032;

use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Player {
    use Time::HiRes qw(tv_interval gettimeofday usleep);


    field $handle;
    field $source  :param  = undef;
    field $link;
    field $silent = 1;


    method handle {
        return $handle;
    }


    method _set_handle ($new_handle) {
        $handle = $new_handle;
    }


    method source () {
        return $source;
    }


    method next_sample {
        return $link->next;
    }


    method silent {
        return $silent;
    }


    method mute {
        $silent = 1;
    }


    method unmute {
        $silent = 0;
    }


    method todo () {
        return $source->current_sample - $link->next;
    }


    method done ($n_samples) {
        $link->done($n_samples);
    }


    method connect ($source) {
        my $offset = $source->current_sample;
        $link = Audio::Aoede::Link->new(offset => $offset);
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Audio::Aoede::Player - a generic player for Aoede

=head1 DESCRIPTION

This module is without much purpose as of now.

=head1 METHODS

FIXME !!

=head1 AUTHOR

Harald Jörg, E<lt>haj@posteo.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Harald Jörg

This module is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
