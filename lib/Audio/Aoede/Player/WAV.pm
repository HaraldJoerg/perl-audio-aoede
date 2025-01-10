package Audio::Aoede::Player::WAV;
use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

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

    sub play_lpcm ($class, $lpcm, $to = undef) {
        $lpcm->write_wav($to);
    }
}

1;

=head1 METHODS

=head2 class method play_lpcm

   $path = Audio::Aoede::Player::WAV->play_lpcm($lpcm,$to)

Send the contents of the L<Audio::Aoede::LPCM> object C<$lpcm> in WAV
file format to C<$to>.  If C<$to> is not provided, create a temporary
file.  Returns the path name of the file written.
