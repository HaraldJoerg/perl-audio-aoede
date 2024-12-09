use utf8;
use Test::More;

use Audio::Aoede::Note;

# A plain note with octave
{
    my $n = Audio::Aoede::Note->from_spn('A4');
    is($n->name,'A',
       'The note has the expected name.');
    ok(defined $n->accidental,
       'The accidental is defined even if none was given');
    is($n->accidental,0,
       'A plain note has a zero accidental');
    is($n->octave,4,
       'The note has the expected octave (ASCII).');
}

# Octave given as Unicode subscript
{
    my $n = Audio::Aoede::Note->from_spn('B₄');
    is($n->octave,4,
       'The note has the expected octave (Unicode subscript).');
}

# Accidentals
{
    my $n = Audio::Aoede::Note->from_spn('Cbb');
    is($n->accidental,-2,
       'The note has the expected accidental (ASCII -2)');
}
{
    my $n = Audio::Aoede::Note->from_spn('D𝄫');
    is($n->accidental,-2,
       'The note has the expected accidental (Unicode -2)');
}
{
    my $n = Audio::Aoede::Note->from_spn('Eb');
    is($n->accidental,-1,
       'The note has the expected accidental (ASCII -1)');
}
{
    my $n = Audio::Aoede::Note->from_spn('F♭');
    is($n->accidental,-1,
       'The note has the expected accidental (Unicode -1)');
}
{
    my $n = Audio::Aoede::Note->from_spn('G#');
    is($n->accidental,1,
       'The note has the expected accidental (ASCII +1)');
}
{
    my $n = Audio::Aoede::Note->from_spn('A♯');
    is($n->accidental,1,
       'The note has the expected accidental (Unicode +1)');
}
{
    my $n = Audio::Aoede::Note->from_spn('B##');
    is($n->accidental,2,
       'The note has the expected accidental (ASCII +2)');
}
{
    my $n = Audio::Aoede::Note->from_spn('C𝄪');
    is($n->accidental,2,
       'The note has the expected accidental (Unicode +2)');
}

# Error handling
use Test::Fatal;
{
    like(exception { Audio::Aoede::Note->from_spn('𝄪') },qr('𝄪'),
       'Unparsable SPN raises an exception showing the string');
}

done_testing;
