use strict;
use warnings;

use Test::More 0.88;

eval {
    require DateTime;
    require DateTime::TimeZone::Local;
    require DateTime::TimeZone::Local::Win32;
};
if ($@) {
    plan skip_all => 
        'These tests run only when DateTime and DateTime::TimeZone are present.';
}

use constant {
    DT_TZ_MIN => 1.98,
};

my $Registry;
use Win32::TieRegistry 0.27 ( TiedRef => \$Registry, Delimiter => q{/} );

my $Tzi_Key;
sub get_tzi_key {
    return $Tzi_Key ||= $Registry->Open(
        'LMachine/SYSTEM/CurrentControlSet/Control/TimeZoneInformation/', {
            Access => Win32::TieRegistry::KEY_READ()
              | Win32::TieRegistry::KEY_WRITE()
          }
    );    
}

my $Minimum_DT_TZ = $DateTime::TimeZone::Local::VERSION >= DT_TZ_MIN;
my $Registry_Writable = get_tzi_key() ? 1 : 0;

my $WindowsTZKey;
sub windows_tz_names {
    $WindowsTZKey = $Registry->Open(
        'LMachine/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Time Zones/',
        { Access => Win32::TieRegistry::KEY_READ() }
    );

    $WindowsTZKey ||= $Registry->Open(
        'LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Time Zones/',
        { Access => Win32::TieRegistry::KEY_READ() }
    );

    return unless $WindowsTZKey;

    return $WindowsTZKey->SubKeyNames();
}

sub set_and_test_windows_tz {
    my $windows_tz_name = shift;
    my $iana_name      = shift;

    if ($Registry_Writable)
    {
        if (   defined $Tzi_Key
            && defined $Tzi_Key->{'/TimeZoneKeyName'}
            && $Tzi_Key->{'/TimeZoneKeyName'} ne '' ) {
            local $Tzi_Key->{'/TimeZoneKeyName'} = $windows_tz_name;

            test_windows_zone( $windows_tz_name, $iana_name );
        }
        else {
            local $Tzi_Key->{'/StandardName'} = (
                  $WindowsTZKey->{ $windows_tz_name . q{/} }
                ? $WindowsTZKey->{ $windows_tz_name . '/Std' }
                : 'MAKE BELIEVE VALUE'
            );

            test_windows_zone( $windows_tz_name, $iana_name );
        }
    }
    else
    {
        test_windows_zone( $windows_tz_name, $iana_name );
    }
}

sub test_windows_zone {
    my $windows_tz_name = shift;
    my $iana_name      = shift;
    my %KnownBad = map { $_ => 1 } ();

    my $tz;
    if ( $Registry_Writable && $Minimum_DT_TZ ) {
        $tz = DateTime::TimeZone::Local::Win32->FromRegistry();

        ok(
            $tz && DateTime::TimeZone->is_valid_name( $tz->name() ),
            "$windows_tz_name - found valid IANA time zone '" .
            DateTime::TimeZone::Local::Win32->_FindWindowsTZName() . "' from Windows"
        );
    }
    else {
        my $tz_name = DateTime::TimeZone::Local::Win32->_WindowsToIANA( $windows_tz_name );
        ok (
            defined $tz_name && DateTime::TimeZone->is_valid_name( $tz_name ),
            "$windows_tz_name - found valid IANA time zone '" . $windows_tz_name . "' from Hash"
        );
    }

    if ( defined $iana_name ) {
        my $desc = "$windows_tz_name was mapped to $iana_name";
        if ( $Registry_Writable && $tz && $Minimum_DT_TZ ) {
            is( $tz->name(), $iana_name, "$desc (Registry)" );
        }
        elsif ( $Registry_Writable && $Minimum_DT_TZ ) {
            fail("$desc (Registry)");
        }
        else {
            my $tz_name = DateTime::TimeZone::Local::Win32->_WindowsToIANA( $windows_tz_name );
            is ( $tz_name, $iana_name, "$desc (Hash)" );
        }
    }
    else {
        SKIP: {
            unless ( $ENV{'AUTHOR_TESTING'} && $Registry_Writable ) {
                skip (
                    "$windows_tz_name - Windows offset matches IANA offset (Maintainer only)",
                    1
                );
            }
            if ( !$tz || !DateTime::TimeZone->is_valid_name( $tz->name() ) ) {
                skip (
                    "Time Zone display for $windows_tz_name not testable",
                    1
                );
            }
            my $dt = DateTime->now(
                time_zone => $tz->name(),
            );

            my $iana_offset = int( $dt->strftime("%z") );
            $iana_offset -= 100 if $dt->is_dst();
            my $windows_offset
                = $WindowsTZKey->{"${windows_tz_name}/Display"};

            if ( $windows_offset =~ /^\((?:GMT|UTC)\).*$/ ) {
                $windows_offset = 0;
            }
            else {
                if ( $windows_offset
                    =~ s/^\((?:GMT|UTC)(.*?):(.*?)\).*$/$1$2/ ) {
                    $windows_offset = int($windows_offset);
                }
                else {
                    skip (
                        "Time Zone display for $windows_tz_name not testable",
                        1
                    );
                }
            }

            if ( $KnownBad{$windows_tz_name} ) {
            TODO: {
                    local $TODO
                        = "Microsoft has some out-of-date time zones relative to IANA";
                    is(
                        $iana_offset, $windows_offset,
                        "$windows_tz_name - Windows offset matches IANA offset"
                    );
                    return;
                }
            }
            elsif ( defined $WindowsTZKey->{"${windows_tz_name}/IsObsolete"}
                && $WindowsTZKey->{"${windows_tz_name}/IsObsolete"} eq
                "0x00000001" ) {
                skip (
                    "$windows_tz_name - deprecated by Microsoft",
                    1
                );
            }
            else {
                is(
                    $iana_offset, $windows_offset,
                    "$windows_tz_name - Windows offset matches IANA offset"
                );
            }
        }
    }
}

1;
