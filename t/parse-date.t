use v6;
use Test;
use DateTime::Parse;

plan *;

sub d ($y, $m, $d) { Date.new: $y, $m, $d }

multi sub p ($s, *%_) { ~ parse-date $s, |%_ }

multi sub p ($s, $y, $m, $d, *%_) { ~ 
    parse-date $s, today => d($y, $m, $d), |%_
}

my $today = d 1997, 7, 2; # A Wednesday.

sub t ($s, *%_) { ~ parse-date $s, :$today, |%_ }

# ------------------------------------------------------------
# Year, month, and day
# ------------------------------------------------------------

is p('1994 12 6'),        '1994-12-06', 'yyyy mm dd';
is p('1994  12   6'),     '1994-12-06', 'yyyy mm dd (with spaces)';
is p('1994  12  06'),     '1994-12-06', 'yyyy mm dd (with spaces and leading 0)';
is p('06  12 1994'),      '1994-12-06', 'dd mm yyyy';
is p('06/12/1994'),       '1994-12-06', 'dd/mm/yyyy';
is p('19941206'),         '1994-12-06', 'yyyymmdd';

is t('6 12 94'),                   '1994-12-06', 'dd mm yy';
is p('6 12 94', 1942, 7, 7),       '1894-12-06', 'dd mm yy (different :today, 1)';
is p('6 12 94', :yy-center(1942)), '1894-12-06', 'dd mm yy (:yy-center, 1)';
is p('6 12 94', 2055, 7, 7),       '2094-12-06', 'dd mm yy (different :today, 2)';
is p('6 12 94', :yy-center(2055)), '2094-12-06', 'dd mm yy (:yy-center, 2)';
is t('6/12/94'),                   '1994-12-06', 'dd/mm/yy';
is t('6-12-94'),                   '1994-12-06', 'dd-mm-yy';
is t('12 6 94', :mdy),             '1994-12-06', 'mm dd yy';
is t('12/6/94', :mdy),             '1994-12-06', 'mm/dd/yy';
is t('12-6-94', :mdy),             '1994-12-06', 'mm-dd-yy';

is p('06 Dec 1994'),         '1994-12-06', 'dd Mon yyyy';
 is p('6Dec 1994'),           '1994-12-06', 'ddMon yyyy';
 is p('6 Dec1994'),           '1994-12-06', 'dd Monyyyy';
 is p('6Dec1994'),            '1994-12-06', 'ddMonyyyy';
is p('6 December 1994'),     '1994-12-06', 'dd Monthname yyyy';
 is p('6December1994'),       '1994-12-06', 'ddMonthnameyyyy';
is p('6th December, 1994'),  '1994-12-06', 'dd"th" Monthname, yyyy';
is p('1st December 1994'),   '1994-12-01', 'dd"st" Monthname yyyy';
is p('2nd December 1994'),   '1994-12-02', 'dd"nd" Monthname yyyy';
is p('3rd December 1994'),   '1994-12-03', 'dd"rd" Monthname yyyy';
is p('Dec 6 1994'),          '1994-12-06', 'Mon dd yyyy';
 is p('Dec6 1994'),           '1994-12-06', 'Mondd yyyy';
is p('December 06, 1994'),   '1994-12-06', 'Monthname dd, yyyy';
is p('December 6th, 1994'),  '1994-12-06', 'Monthname dd"th" yyyy';
is p('1994 Dec 6'),          '1994-12-06', 'yyyy Mon dd';
is p('1994 6 Dec'),          '1994-12-06', 'yyyy dd Mon';

is t('6 December 94'), '1994-12-06', 'dd Monthname yy';
 is t('6December94'), '1994-12-06', 'ddMonthnameyy';
is t('Dec 6 94'),      '1994-12-06', 'Mon dd yy';

# Ignore the day of week when the month and day are given.
# (6 December 1994 was a Tuesday.)

is p('1994 12 6 Fr'),        '1994-12-06', 'yyyy mm dd Dow';
is p('1994 12 6 Friday'),    '1994-12-06', 'yyyy mm dd Dayofweek';
is p('Fr 1994 12 6'),        '1994-12-06', 'Dow yyyy mm dd';
is p('Friday, 1994 12 6'),   '1994-12-06', 'Dayofweek, yyyy mm dd';
is t('Fr, 6 December 94'),   '1994-12-06', 'Dow, dd Monthname yy';

# ------------------------------------------------------------
# Month and day
# ------------------------------------------------------------

# When :past and :future are omitted, we pick the year that
# yields the date nearest today.

is t('6 10'),                 '1997-10-06', 'dd mm';
is t('6/10'),                 '1997-10-06', 'dd/mm';
is t('10 6', :mdy),           '1997-10-06', 'mm dd';
is t('10/6', :mdy),           '1997-10-06', 'mm/dd';
is t('6 Oct'),                '1997-10-06', 'dd Mon';
is t('6 October'),            '1997-10-06', 'dd Monthname';
is t('6th October'),          '1997-10-06', 'dd"th" Monthname';
is t('Oct 6'),                '1997-10-06', 'Mon dd';
is t('Oct 6th'),              '1997-10-06', 'Mon dd"th"';
is t('October 6'),            '1997-10-06', 'Monthname dd';
is t('Fri October 6'),        '1997-10-06', 'Dow Monthname dd';
  # 6 October 1997 was a Monday.

is t('Jul  2'),               '1997-07-02', 'Mon dd (today)';

is t('Dec  9'),               '1997-12-09', 'Mon dd (Jul to Dec)';
is p('Dec  9', 1997,  1,  1), '1996-12-09', 'Mon dd (Jan to Dec)';
is p('Dec  9', 1997,  3,  3), '1996-12-09', 'Mon dd (Mar to Dec)';
is p('Dec  9', 1997, 12,  3), '1997-12-09', 'Mon dd (Dec to Dec, forwards)';
is p('Dec  9', 1997, 12, 15), '1997-12-09', 'Mon dd (Dec to Dec, backwards)';

is t('Jan 18'),               '1997-01-18', 'Mon dd (Jul to Jan)';
is p('Jan 18', 1997, 12, 31), '1998-01-18', 'Mon dd (Dec to Jan)';
is p('Jan 18', 1997,  3,  3), '1997-01-18', 'Mon dd (Mar to Jan)';
is p('Jan 18', 1997,  1,  1), '1997-01-18', 'Mon dd (Jan to Jan, forwards)';
is p('Jan 18', 1997,  1, 30), '1997-01-18', 'Mon dd (Jan to Jan, backwards)';

is p('Dec 25', 1989,  6, 25), '1988-12-25', 'Mon dd (preferring past by 1 day)';
is p('Dec 25', 1989,  6, 26), '1989-12-25', 'Mon dd (preferring future by 1 day)';
is p('Dec 25', 1988,  6, 25), '1988-12-25', 'Mon dd (preferring future in case of a tie)';
is p('Dec 25', 1988,  6, 24), '1987-12-25', 'Mon dd (…but we can still go backwards in a leap year)';

# With :past, never go forwards.

is t('Mar 22', :past),        '1997-03-22', 'Mon dd (unnecessary :past)';
is t('Dec  6', :past),        '1996-12-06', 'Mon dd (:past)';

is p('Jan  2', 1997,  1,  1, :past), '1996-01-02', 'Mon dd (:past, Jan  1 to Jan  2)';
is p('Jan  2', 1997,  1,  2, :past), '1997-01-02', 'Mon dd (:past, Jan  2 to Jan  2)';
is p('Jan  2', 1997,  1,  3, :past), '1997-01-02', 'Mon dd (:past, Jan  3 to Jan  2)';
is p('Dec 30', 1997, 12, 31, :past), '1997-12-30', 'Mon dd (:past, Dec 31 to Dec 30)';
is p('Dec 30', 1997, 12, 30, :past), '1997-12-30', 'Mon dd (:past, Dec 30 to Dec 30)';
is p('Dec 30', 1997, 12, 29, :past), '1996-12-30', 'Mon dd (:past, Dec 29 to Dec 30)';

# With :future, never go backwards.

is t('Dec  6', :future),      '1997-12-06', 'Mon dd (unnecessary :future)';
is t('Mar 22', :future),      '1998-03-22', 'Mon dd (:future)';

is p('Jan  2', 1997,  1,  1, :future), '1997-01-02', 'Mon dd (:future, Jan  1 to Jan  2)';
is p('Jan  2', 1997,  1,  2, :future), '1997-01-02', 'Mon dd (:future, Jan  2 to Jan  2)';
is p('Jan  2', 1997,  1,  3, :future), '1998-01-02', 'Mon dd (:future, Jan  3 to Jan  2)';
is p('Dec 30', 1997, 12, 31, :future), '1998-12-30', 'Mon dd (:future, Dec 31 to Dec 30)';
is p('Dec 30', 1997, 12, 30, :future), '1997-12-30', 'Mon dd (:future, Dec 30 to Dec 30)';
is p('Dec 30', 1997, 12, 29, :future), '1997-12-30', 'Mon dd (:future, Dec 29 to Dec 30)';

# ------------------------------------------------------------
# Day of the week
# ------------------------------------------------------------

# Without :past, bare days of the week are assumed to refer
# to the future.

is t('Monday'),       '1997-07-07', 'Dayofweek';
is t('Mon'),          '1997-07-07', 'Dow (1)';
is t('Mon', :future), '1997-07-07', 'Dow (unnecessary :future, 1)';
is t('Mon', :past),   '1997-06-30', 'Dow (:past, 1)';

# Try the same thing with a day of the week that's after Wednesday.

is t('Fri'),          '1997-07-04', 'Dow (2)';
is t('Fri', :future), '1997-07-04', 'Dow (unnecessary :future, 2)';
is t('Fri', :past),   '1997-06-27', 'Dow (:past, 2)';

# How about Wednesday itself? A bare day of the week never yields
# today.

is t('Wed'),          '1997-07-09', 'Dow (of today, yielding next week)';
is t('Wed', :future), '1997-07-09', 'Dow (of today, unnecessary :future)';
is t('Wed', :past),   '1997-06-25', 'Dow (of today, :past)';

# Tests starting from different days.

{
    my $d = Date.new(1922, 4, 3); # A Monday.
    is p('Mon', :today($d)),        '1922-04-10', 'Dow (Mon to Mon, forwards)';
    is p('Mon', :today($d), :past), '1922-03-27', 'Dow (Mon to Mon, backwards)';
    is p('Tue', :today($d)),        '1922-04-04', 'Dow (Mon to Tue, forwards)';
    is p('Tue', :today($d), :past), '1922-03-28', 'Dow (Mon to Tue, backwards)';
    is p('Sat', :today($d)),        '1922-04-08', 'Dow (Mon to Sat, forwards)';
    is p('Sat', :today($d), :past), '1922-04-01', 'Dow (Mon to Sat, backwards)';
}

{
    my $d = Date.new(2031, 10, 19); # A Sunday.
    is p('Sun', :today($d)),        '2031-10-26', 'Dow (Sun to Sun, forwards)';
    is p('Sun', :today($d), :past), '2031-10-12', 'Dow (Sun to Sun, backwards)';
    is p('Mon', :today($d)),        '2031-10-20', 'Dow (Sun to Mon, forwards)';
    is p('Mon', :today($d), :past), '2031-10-13', 'Dow (Sun to Mon, backwards)';
    is p('Sat', :today($d)),        '2031-10-25', 'Dow (Mon to Sat, forwards)';
    is p('Sat', :today($d), :past), '2031-10-18', 'Dow (Mon to Sat, backwards)';
}

# ------------------------------------------------------------
# "next" and "last"
# ------------------------------------------------------------

is t('next Sat'),          '1997-07-05', '"next" Dow (unnecessary)';
is t('next Sat', :future), '1997-07-05', '"next" Dow (unnecessary :future)';
is t('next Sat', :past),   '1997-07-05', '"next" Dow (overriding :past)';

is t('last Sat'),          '1997-06-28', '"last" Dow';
is t('last Sat', :past),   '1997-06-28', '"last" Dow (unnecessary :past)';
is t('last Sat', :future), '1997-06-28', '"last" Dow (overriding :future)';

is t('Sat after next'),    '1997-07-12', 'Dow "after next" (1)';
is t('Tue after next'),    '1997-07-15', 'Dow "after next" (2)';

is t('Sat before last'),   '1997-06-21', 'Dow "before last" (1)';
is t('Tue before last'),   '1997-06-24', 'Dow "before last" (2)';

is t('next week'),         '1997-07-09', '"next week"';
is t('last week'),         '1997-06-25', '"last week"';

is t('week after next'),   '1997-07-16', '"week after next"';
is t('week before last'),  '1997-06-18', '"week before last"';

# ------------------------------------------------------------
# Special name
# ------------------------------------------------------------

is t('yesterday'), '1997-07-01', '"yesterday"';
is t('today'),     '1997-07-02', '"today"';
is t('tomorrow'),  '1997-07-03', '"tomorrow"';

# Also allow three-character abbreviations.

is t('yes'), '1997-07-01', '"yes"(terday)';
is t('tod'), '1997-07-02', '"tod"(ay)';
is t('tom'), '1997-07-03', '"tom"(orrow)';

done_testing;
