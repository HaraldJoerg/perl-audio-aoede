# perl-audio-aoede
Sound from scratch, calculated with the Perl programming language

**Caveat Emptor:** The current state of the project uses the "grid
geometry manager" of Prima and therefore works only with
[Prima](https://github.com/dk/Prima) installed from Git.  The grid
geometry manager has not yet been released on CPAN.

This is a side project from a side project, but it turned out to be a
lot of fun so that I'll probably continue to spend some of my spare
time on it.

It started with my interest for the
[Corinna](https://github.com/Perl-Apollo/Corinna) project to bring
"modern" object orientation into the core of the Perl programming
language.

Then I noticed (a few years ago) that my favourite editor
[Emacs](https://www.gnu.org/software/emacs/) does not understand newer
Perl syntax, and as a side project I added missing stuff to
CPerl mode.  So, upcoming Emacs 30 will understand Perl syntax
including Perl 5.40.

While working on this I noticed that - as could be expected - there is
not much code out there in the wild which already uses the new Perl
syntax.  So, to get some test and practice, I had to write my own.

So this project was started to test CPerl mode and at the same time
have fun.  For the Perl code this means that it isn't very consistent
in its style *intentionally* because I needed CPerl mode to cover
different coding styles.  The repository also contains some dead code
and many undocumented features.  Sorry for that.

Part of this work was the specification of a file format which I could
use to thest the audio software: It should be easy to write for humans
(unlike MIDI).  This spec is now
[here](https://github.com/HaraldJoerg/perl-audio-aoede/blob/main/lib/Audio/Aoede/MusicRoll/Format.pod),
but unfortunately GitHub's POD rendering clobbers Unicode characters
in Code sections.  Also, HTML rendering of musical note symbols looks
worse than I expected even when correctly decoded, so perhaps I'll
drop that.

The `eg` directory has a few examples of music roll files which can be
played with the program `bin/mrt_play`.  This needs the `sox` program
to be on your path.

Two of the samples created by mrt_play (~300kB, ~30 seconds each)
are at https://haraldjoerg.github.io/i/entertainer.ogg and
https://haraldjoerg.github.io/i/lvb_27_2.ogg .
