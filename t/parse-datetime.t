use v6;
use Test;
use DateTime::Parse;

plan *;

# ------------------------------------------------------------

my &f = { parse-datetime "5 Mar 2008 $^s", :utc };

is f('14:56'),           '2008-03-05T14:56:00Z', 'dd Mon yyyy hh:mm';
is f('14:56:07'),        '2008-03-05T14:56:07Z', 'dd Mon yyyy hh:mm:ss';
is f('14:56:07.3'),      '2008-03-05T14:56:07Z', 'dd Mon yyyy hh:mm:ss.s';
is f('14:56:07.3').second,       7 + 3/10,       'dd Mon yyyy hh:mm:ss.s (subsecond check)';
is f('14:56:07.333'),    '2008-03-05T14:56:07Z', 'dd Mon yyyy hh:mm:ss.sss';
is f('14:56:07.333').second,   7 + 333/1000,     'dd Mon yyyy hh:mm:ss.sss (subsecond check)';

is f('2:56 AM'),         '2008-03-05T02:56:00Z', 'dd Mon yyyy h:mm "AM"';
is f('2:56 PM'),         '2008-03-05T14:56:00Z', 'dd Mon yyyy h:mm "PM"';
is f('2:56:07 AM'),      '2008-03-05T02:56:07Z', 'dd Mon yyyy h:mm:ss "AM"';
is f('2:56:07.333 AM'),  '2008-03-05T02:56:07Z', 'dd Mon yyyy h:mm:ss.sss "AM"';
is f('2:56:07.333 AM').second, 7 + 333/1000,     'dd Mon yyyy h:mm:ss.sss "AM" (subsecond check)';
is f('2:56 am'),         '2008-03-05T02:56:00Z', 'dd Mon yyyy h:mm "am"';
is f('2:56am'),          '2008-03-05T02:56:00Z', 'dd Mon yyyy h:mm"am"';
is f('2 am'),            '2008-03-05T02:00:00Z', 'dd Mon yyyy h "am"';
is f('2am'),             '2008-03-05T02:00:00Z', 'dd Mon yyyy h"am"';

is f('noon'),            '2008-03-05T12:00:00Z', 'dd Mon yyyy "noon"';
is f('12 noon'),         '2008-03-05T12:00:00Z', 'dd Mon yyyy "12 noon"';
is f('12:00 noon'),      '2008-03-05T12:00:00Z', 'dd Mon yyyy "12:00 noon"';
is f('12 PM'),           '2008-03-05T12:00:00Z', 'dd Mon yyyy "12 PM"';

is f('midnight'),        '2008-03-05T00:00:00Z', 'dd Mon yyyy "midnight"';
is f('12 midnight'),     '2008-03-05T00:00:00Z', 'dd Mon yyyy "12 midnight"';
is f('12:00 midnight'),  '2008-03-05T00:00:00Z', 'dd Mon yyyy "12:00 midnight"';
is f('0:00'),            '2008-03-05T00:00:00Z', 'dd Mon yyyy "0:00"';
is f('00:00'),           '2008-03-05T00:00:00Z', 'dd Mon yyyy "00:00"';
is f('12 AM'),           '2008-03-05T00:00:00Z', 'dd Mon yyyy "12 AM"';

# ------------------------------------------------------------

&f = { parse-datetime "11 Mar 2007 $^s", :$^timezone };

is f('5:06 PM', 2*60*60 + 3*60), '2007-03-11T17:06:00+0203', 'Absolute with timezone (+)';
is f('2:13:14', -(12*60*60 + 6*60)), '2007-03-11T02:13:14-1206', 'Absolute with timezone (-)';

sub nyc2007-tz($dt, $to-utc) {
    my $t = ($dt.month, $dt.day, $dt.hour);
    my $critical-hour = $to-utc ?? 2 !! 7;
    my $dst =
        ([or] (3, 11, $critical-hour) »<=>« $t) == 0|-1 &&
        ([or] $t »<=>« (11, 4, $critical-hour)) == -1;
    3600 * ($dst ?? -4 !! -5);
}

is f('1:55 am', &nyc2007-tz), '2007-03-11T01:55:00-0500', 'Absolute with timezone (Callable, before DST)';
is f('3:02 am', &nyc2007-tz), '2007-03-11T03:02:00-0400', 'Absolute with timezone (Callable, in DST)';

# ------------------------------------------------------------

&f = &parse-datetime;
sub y ($year) { { now => DateTime.new(:$year) } }

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

is f('6 Jun 06 6:12 am', :local).timezone, $*TZ, ':local';
is f('6 Jun 06 6:12 am', |y(1988), :local).timezone, $*TZ, ':local with conflicting :now';

done_testing;
