use v6;
use Test;
use DateTime::Parse;

plan *;

my &f = { parse-datetime "5 Mar 2008 $^s" };

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

is f('midnight'),        '2008-03-05T00:00:00Z', 'dd Mon yyyy "midnight"';
is f('12 midnight'),     '2008-03-05T00:00:00Z', 'dd Mon yyyy "12 midnight"';
is f('12:00 midnight'),  '2008-03-05T00:00:00Z', 'dd Mon yyyy "12:00 midnight"';
is f('0:00'),            '2008-03-05T00:00:00Z', 'dd Mon yyyy "0:00"';
is f('00:00'),           '2008-03-05T00:00:00Z', 'dd Mon yyyy "00:00"';

done_testing;
