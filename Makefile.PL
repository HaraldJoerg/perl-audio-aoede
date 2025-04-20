use 5.036;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Audio::Aoede',
    VERSION_FROM      => 'lib/Audio/Aoede.pm',
    MIN_PERL_VERSION => '5.036',
    PREREQ_PM         => {
	'Carp'                   => 0,
        'Exporter'               => 0,
        'File::Spec'             => 0,
        'File::Temp'             => 0,
        'FindBin'                => 0,
        'Feature::Compat::Class' => '0.07',
        'Getopt::Long'           => 0,
        'List::Util'             => 0,
        'MIDI::Simple'           => 0,
        'MIDI::SoundFont'        => 0,
        'PDL'                    => '2.100',
        'PDL::DSP::Windows'      => 0,
        'PDL::Graphics::Prima'   => 0,
        'Prima'                  => 1.76,
        'Scalar::Util'           => 0,
        'Time::HiRes'            => 0,
    },
    CONFIGURE_REQUIRES => {
        'PDL'  => '2.100',
    },
    BUILD_REQUIRES => {
        'PDL'  => '2.100',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88', # done_testing
        'Test::PDL' => '0.21',
    },
    ABSTRACT_FROM     => 'lib/Audio/Aoede.pm', 
    AUTHOR            => 'Harald Jörg <haj@posteo.de>',
    LICENSE           => 'perl',
);

# From the pp_template template
{
    my @pd_srcs;
    package MY;                 # so that "SUPER" works right
    sub init_PM {
        my ($self) = @_;
        $self->SUPER::init_PM;
        @pd_srcs = ::pdlpp_eumm_update_deep($self);
    }
    sub postamble { ::pdlpp_postamble(@pd_srcs) }
}
