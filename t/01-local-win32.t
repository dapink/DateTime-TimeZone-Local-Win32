use strict;
use warnings;

use Test::More 0.88;

require './t/lib/tools.pl';

note "Test basic time zones"; {
    my $denver_time_zone_with_newlines = join( '', "Mountain Standard Time", map { chr } qw(  0 10 0 0 0 0 0 0
        82 0 0 0 63 32 0 0 63 120 0 0 32 0 0 0 72 0 0 0 64 116 122 114 101 115
        46 100 108 108 44 45 49 57 50 0 0 0 0 0 1 0 0 0 63 13 0 0 63 63 63 0 63
        13 0 0 1 0 0 0 64 116 122 114 101 115 46 100 108 108 44 45 49 57 49 0 72
        0 0 0 0 0 0 0 63 120 0 0 213 63 63 0 0 0 0 0 0 ) );

    foreach my $pair (
        [ 'Eastern Standard Time',  'America/New_York' ],
        [ 'Dateline Standard Time', '-1200' ],
        [ 'Israel Standard Time',   'Asia/Jerusalem' ],
        [ $denver_time_zone_with_newlines, 'America/Denver' ],
    ) {
        set_and_test_windows_tz( @{$pair} );
    }
}

done_testing();
