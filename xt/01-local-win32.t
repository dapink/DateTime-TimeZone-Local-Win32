use strict;
use warnings;

use Test::More 0.88;

require './t/lib/tools.pl';

note "Test all windows TZ names"; {
    foreach my $win_tz_name ( windows_tz_names() ) {
        set_and_test_windows_tz( $win_tz_name, undef );
    }
}

done_testing();
