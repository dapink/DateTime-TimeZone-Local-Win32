# Contributing to DateTime-TimeZone-Local-Win32

Bug reports and pull requests are welcome on GitHub:
<https://github.com/dapink/DateTime-TimeZone-Local-Win32>

For security problems, please follow [SECURITY.md](SECURITY.md) instead of
opening a public issue.

## Reporting a Bug

Please open an issue and include:

- the version of this module, of Perl and of DateTime::TimeZone
  (`perl -MDateTime::TimeZone -e "print DateTime::TimeZone->VERSION"`)
- your Windows version and build (run `winver`)
- your Windows time zone name, from
  `reg query "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v TimeZoneKeyName`
- what you expected, and what happened instead, including any error message

## How the Time Zone Mapping Works

This module maps the Windows time zone name to an IANA time zone name. The
offsets and daylight saving rules come from DateTime::TimeZone, so a change to
a country's rules only needs a new DateTime::TimeZone release. This module
only needs a change when Windows adds or renames a time zone.

When adding a Windows time zone to the table:

1. If the Windows zone ID itself names an IANA zone, use that zone.
2. Otherwise, use the IANA zone for a city listed in the Windows display name.
3. A Windows zone whose intent is a fixed offset keeps its offset mapping
   (for example, Greenwich Standard Time maps to `GMT`).
4. Never remove an entry. Older versions of Windows report older names, and a
   machine may still be set to a zone Microsoft has marked obsolete.

Please don't change an existing mapping unless it gives a wrong result. CLDR's
[windowsZones.xml](https://github.com/unicode-org/cldr/blob/main/common/supplemental/windowsZones.xml)
is a useful reference for new zones.

## Building and Testing

The distribution is built with [Dist::Zilla](https://dzil.org/). On Windows:

    cpanm Dist::Zilla
    dzil authordeps --missing | cpanm
    dzil listdeps --author --missing | cpanm
    dzil test

The tests that compare every Windows time zone's offsets with
DateTime::TimeZone temporarily set the time zone name in the registry, so
they only run from an elevated (administrator) prompt:

    dzil test --release --automated

Pull requests are also tested on a Windows runner with GitHub Actions.
