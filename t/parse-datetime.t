use v6;
use Test;
use DateTime::Parse;

plan 115;

sub y ($year) { { now => DateTime.new(:$year) } }

my &f;

# ------------------------------------------------------------
# Time before date or date before time
# ------------------------------------------------------------

for False, True -> $date-first {

    &f = { parse-datetime
        $date-first ?? "5 Mar 2008 $^s" !! "$^s 11 Aug 1999",
        :utc };

    sub test($got, $should-be, $desc, $next-day = False, :$subsecond) {
        is $got,
            $subsecond
             ?? $should-be
             !! $date-first
             ?? "2008-03-0{5 + $next-day}T{$should-be}Z"
             !! "1999-08-{11 + $next-day}T{$should-be}Z",
            [~]
                $date-first
                 ?? "dd Mon yyyy $desc"
                 !! "$desc dd Mon yyyy",
                (' (subsecond check)' if $subsecond);
    }

    test f('14:56'),                 '14:56:00',   'hh:mm';
    test f('14:56:07'),              '14:56:07',   'hh:mm:ss';
    test f('14:56:07.3'),            '14:56:07',   'hh:mm:ss.s';
    test f('14:56:07.3').second,     7 + 3/10,     'hh:mm:ss.s', :subsecond;
    test f('14:56:07.333'),          '14:56:07',   'hh:mm:ss.sss';
    test f('14:56:07.333').second,   7 + 333/1000, 'hh:mm:ss.sss', :subsecond;

    test f('2:56 AM'),               '02:56:00',   'h:mm "AM"';
    test f('2:56 PM'),               '14:56:00',   'h:mm "PM"';
    test f('2:56:07 AM'),            '02:56:07',   'h:mm:ss "AM"';
    test f('2:56:07.333 AM'),        '02:56:07',   'h:mm:ss.sss "AM"';
    test f('2:56:07.333 AM').second, 7 + 333/1000, 'h:mm:ss.sss "AM"', :subsecond;
    test f('2:56 am'),               '02:56:00',   'h:mm "am"';
    test f('2:56am'),                '02:56:00',   'h:mm"am"';
    test f('2 am'),                  '02:00:00',   'h "am"';
    test f('2am'),                   '02:00:00',   'h"am"';

    test f('noon'),                  '12:00:00',   '"noon"';
    test f('12 noon'),               '12:00:00',   '"12 noon"';
    test f('12:00 noon'),            '12:00:00',   '"12:00 noon"';
    test f('12 PM'),                 '12:00:00',   '"12 PM"';

    test f('midnight'),              '00:00:00',   '"midnight"';
    test f('12 midnight'),           '00:00:00',   '"12 midnight"';
    test f('12:00 midnight'),        '00:00:00',   '"12:00 midnight"';
    test f('0:00'),                  '00:00:00',   '"0:00"';
    test f('00:00'),                 '00:00:00',   '"00:00"';
    test f('12 AM'),                 '00:00:00',   '"12 AM"';

    test f('10:00 -02'),             '12:00:00',   'hh:mm -hh';
    test f('10:00 UTC-02'),          '12:00:00',   'hh:mm "UTC"-hh';
    test f('noon +0347'),            '08:13:00',   '"noon" +hhmm';
    test f('noon UTC+0347'),         '08:13:00',   '"noon" "UTC"+hhmm';
    test f('8:36 pm -11:11'),        '07:47:00',   'hh "pm" -hh:mm', :next-day;
    test f('8:36 pm UTC-11:11'),     '07:47:00',   'hh "pm" "UTC"-hh:mm', :next-day;

    # For now, abbreviations are interpreted as static offsets, not
    # as time zones with DST or whatnot.
    test f('9 am EST'),              '14:00:00',   'hh "am" TZ';
    test f('9:00 EDT'),              '13:00:00',   'hh:mm TZ';
    test f('3:00:01 pm PST'),        '23:00:01',   'hh:mm:ss "pm" TZ';
    test f('13:13 UTC'),             '13:13:00',   'hh:mm "UTC"';
    test f('13:13 GMT'),             '13:13:00',   'hh:mm "GMT"';
    test f('13:13 UYT'),             '16:13:00',   'hh:mm "UYT"';
}

# ------------------------------------------------------------
# Tricky cases
# ------------------------------------------------------------

&f = &parse-datetime;

is f('6 12 94 11 am', :utc), '1994-12-06T11:00:00Z', 'mm dd yy hh "am"';
is f('6 12 94 11 am', :mdy, :utc), '1994-06-12T11:00:00Z', 'dd mm yy hh "am"';

is f('6 12 11 am', |y(1994), :future), '1994-12-06T11:00:00Z', 'mm dd hh "am"';
is f('6 12 11 am', |y(1994), :future, :mdy), '1994-06-12T11:00:00Z', 'dd mm hh "am"';
is f('Jun 12 11 am', |y(1994), :future), '1994-06-12T11:00:00Z', 'Mon dd hh "am"';
is f('12 Jun 11 am', |y(1994), :future), '1994-06-12T11:00:00Z', 'dd Mon hh "am"';

is f('week after next midnight', |y(2000)), '2000-01-15T00:00:00Z', '"week after next midnight"';
  # Interpreted as "midnight a week after next", not "a week
  # after next midnight".
is f('Friday noon', |y(1988)), '1988-01-08T12:00:00Z', 'Dow "noon"';

# ------------------------------------------------------------
# A time without a date
# ------------------------------------------------------------

sub with-time($hour, $minute, $second, $s, *%_) {
    parse-datetime $s, |%_, now => DateTime.new: 
        year => 1983, month => 7, day => 7,
        :$hour, :$minute, :$second
};

&f = &with-time.assuming(0, 0, 0);

is f('02:56'),          '1983-07-07T02:56:00Z', 'hh:mm';
is f('02:56:07.333'),   '1983-07-07T02:56:07Z', 'hh:mm:ss.sss';
is f('14:56:07.333'),   '1983-07-06T14:56:07Z', 'hh:mm:ss.sss (yesterday)';
is f('2 am'),           '1983-07-07T02:00:00Z', 'hh "am"';
is f('2:56:07.333 pm'), '1983-07-06T14:56:07Z', 'hh:mm:ss.sss "pm"';

is f('11:59:59.999'),   '1983-07-07T11:59:59Z', 'Bare time barely today';
is f('12:00:00.001'),   '1983-07-06T12:00:00Z', 'Bare time barely yesterday';
is f('12:00'),          '1983-07-07T12:00:00Z', 'Bare time barely today (preferring the future)';
is f('0:00'),           '1983-07-07T00:00:00Z', 'Bare time mapping to :now';

&f = &with-time.assuming(15, 38, 7.2);

is f('17:00'),          '1983-07-07T17:00:00Z', 'Bare time just after :now';
is f('13:00'),          '1983-07-07T13:00:00Z', 'Bare time just before :now';
is f('03:38:07.1999'),  '1983-07-08T03:38:07Z', 'Bare time barely future';
is f('03:38:07.2001'),  '1983-07-07T03:38:07Z', 'Bare time barely past';
is f('03:38:07.2'),     '1983-07-08T03:38:07Z', 'Bare time barely future (by preference)';
is f('15:38:07.2'),     '1983-07-07T15:38:07Z', 'Bare time mapping to :now';

&f = &with-time.assuming(15, 38, 7.2, :past);

is f('17:00'),          '1983-07-06T17:00:00Z', 'Bare time just after :now but for :past';
is f('13:00'),          '1983-07-07T13:00:00Z', 'Bare time just before :now (unnecessary :past)';
is f('03:38:07.1999'),  '1983-07-07T03:38:07Z', 'Bare time barely future but for :past';
is f('03:38:07.2001'),  '1983-07-07T03:38:07Z', 'Bare time barely past (unnecessary :past)';
is f('03:38:07.2'),     '1983-07-07T03:38:07Z', 'Bare time barely future by preference but for :past';
is f('15:38:07.2'),     '1983-07-07T15:38:07Z', 'Bare time mapping to :now (unnecessary :past)';

&f = &with-time.assuming(15, 38, 7.2, :future);

is f('17:00'),          '1983-07-07T17:00:00Z', 'Bare time just after :now (unnecessary :future)';
is f('13:00'),          '1983-07-08T13:00:00Z', 'Bare time just before :now but for :future';
is f('03:38:07.1999'),  '1983-07-08T03:38:07Z', 'Bare time barely future (unnecessary :future)';
is f('03:38:07.2001'),  '1983-07-08T03:38:07Z', 'Bare time barely past but for :future';
is f('03:38:07.2'),     '1983-07-08T03:38:07Z', 'Bare time barely future (by preference, unnecessary :future)';
is f('15:38:07.2'),     '1983-07-07T15:38:07Z', 'Bare time mapping to :now (unnecessary :future)';

# ------------------------------------------------------------
# :timezone
# ------------------------------------------------------------

&f = { parse-datetime "11 Mar 2007 $^s", :$^timezone };

is f('5:06 PM', 2*60*60 + 3*60), '2007-03-11T17:06:00+0203', 'Absolute with :timezone (+)';
is f('2:13:14', -(12*60*60 + 6*60)), '2007-03-11T02:13:14-1206', 'Absolute with :timezone (-)';

sub nyc2007-tz($dt, $to-utc) {
    my $t = ($dt.month, $dt.day, $dt.hour);
    my $critical-hour = $to-utc ?? 2 !! 7;
    my $dst =
        ([or] (3, 11, $critical-hour) »<=>« $t) == 0|-1 &&
        ([or] $t »<=>« (11, 4, $critical-hour)) == -1;
    3600 * ($dst ?? -4 !! -5);
}

is f('1:55 am', &nyc2007-tz), '2007-03-11T01:55:00-0500', 'Absolute with :timezone (Callable, before DST)';
is f('3:02 am', &nyc2007-tz), '2007-03-11T03:02:00-0400', 'Absolute with :timezone (Callable, during DST)';

is parse-datetime('6 Jun 06 6:12 am', :local).timezone, $*TZ, ':local';
is parse-datetime('6 Jun 06 6:12 am', |y(1988), :local).timezone, $*TZ, ':local with conflicting :now';
