use 5.038;
while (<>) {
    next if /^!/;
    next if /^#/;
    next unless /\S/;
    my $total = 0;
    my @notes = split /\s+/;
    my $previous;
    for my $note (@notes) {
        next unless $note;
        my ($num,$den) = $note =~ m!(\d+)(?:/(\d+))?:!;
        my $duration;
        if ($num) {
            $duration = $den ? $num/$den : $num;
        }
        else {
            $duration = $previous  or  die "No duration in '$_'";
        }
        $previous = $duration;
        $total += $duration;
    }
    say "Line $. : $total";
}
