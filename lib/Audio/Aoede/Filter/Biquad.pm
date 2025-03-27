# ABSTRACT: A Biquad filter for real-time application
package Audio::Aoede::Filter::Biquad;
use 5.038;

use strict;
use warnings;
use Math::Trig qw(pi tan);

sub new {
    my ($class, %opts) = @_;
    my $self = {
        samplerate => $opts{samplerate} || 48000,
        cutoff     => $opts{cutoff} || 1000,    # Hz
        q          => $opts{q} || 0.707,        # Q factor (1/sqrt(2) = no resonance)
        a0 => 0, a1 => 0, a2 => 0,
        b1 => 0, b2 => 0,
        z1 => 0, z2 => 0,  # Delay buffers (y[n-1], y[n-2])
    };
    bless $self, $class;
    $self->_recalculate();
    return $self;
}

sub set_cutoff {
    my ($self, $cutoff) = @_;
    $self->{cutoff} = $cutoff;
    $self->_recalculate();
}

sub set_q {
    my ($self, $q) = @_;
    $self->{q} = $q;
    $self->_recalculate();
}

sub _recalculate {
    my ($self) = @_;
    my $sr = $self->{samplerate};
    my $fc = $self->{cutoff};
    my $q  = $self->{q};

    my $w0 = 2 * pi * $fc / $sr;
    my $alpha = sin($w0) / (2 * $q);

    my $cos_w0 = cos($w0);

    my $b0 = (1 - $cos_w0) / 2;
    my $b1 = 1 - $cos_w0;
    my $b2 = (1 - $cos_w0) / 2;
    my $a0 = 1 + $alpha;
    my $a1 = -2 * $cos_w0;
    my $a2 = 1 - $alpha;

    # Normalize coefficients
    $self->{a0} = $b0 / $a0;
    $self->{a1} = $b1 / $a0;
    $self->{a2} = $b2 / $a0;
    $self->{b1} = $a1 / $a0;
    $self->{b2} = $a2 / $a0;
}

sub process_sample {
    my ($self, $x) = @_;

    my $y = $self->{a0} * $x
          + $self->{a1} * $self->{z1}
          + $self->{a2} * $self->{z2}
          - $self->{b1} * $self->{z1}
          - $self->{b2} * $self->{z2};

    # Update delay buffers
    $self->{z2} = $self->{z1};
    $self->{z1} = $y;

    return $y;
}

1;
