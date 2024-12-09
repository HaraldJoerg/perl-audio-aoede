package Audio::Aoede::Snapshot;
use 5.032;
use Feature::Compat::Class;
use feature 'signatures';
no warnings 'experimental';

class Audio::Aoede::Snapshot 0.01 {
    field $time     :param;
    field $duration :param;
    field $rate     :param; # a bit redundant, this one
    field $channels :param;
    field $spectra  :param;

    method time { $time }
    method spectra { $spectra }
}
1;
