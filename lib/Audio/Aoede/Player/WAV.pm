use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';
use Audio::Aoede::Player;

class Audio::Aoede::Player::WAV
    :isa(Audio::Aoede::Player)
{
    use Carp;

    field $path :param = undef;
    ADJUST {
        my $handle;
        if ($path) {
            open ($handle, '>', $path)
                or croak qq(Can not write to '$path': '$!');
        }
        else {
            $handle = File::Temp->new(SUFFIX => '.wav',
                                      UNLINK => 0);
            $path = "$handle";
        }
        binmode $handle;
        $self->_set_handle($handle);
    }

    method path {
        return $path;
    }

    method write_lpcm ($lpcm) {
        $lpcm->write_wav($self->handle);
    }
}

1;
