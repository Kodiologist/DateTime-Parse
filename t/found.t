use v6;
use Test;
use DateTime::Parse;

# Here we try parsing some real timestamps I found on the Web.

plan 15;

my $d = DateTime.new: day => 5, month => 3, year => 2008;

my &f;

# ------------------------------------------------------------

&f = { parse-datetime $^s, now => $d };

is f('January 12, 2008 - 5:52pm'), '2008-01-12T17:52:00Z', 'Monthname dd, yyyy h:mm"pm"';
is f('January 11, 2008 at 9:36 am'), '2008-01-11T09:36:00Z', 'Monthname dd, yyyy "at" h:mm "am"';
is f('Fri 11 January 2008 @ 19:46'), '2008-01-11T19:46:00Z', 'Dow dd Monthname yyyy "@" hh:mm';
is f('Fri Jun 11, 10:14 am'), '2008-06-11T10:14:00Z', 'Dow Mon dd, hh:mm "am"';
is f('Thursday, June 10, 2010 - 1:44 am'), '2010-06-10T01:44:00Z', 'Dayofweek, Month dd, yyyy - h:mm "am"';
is f('November 13th, 2010 10:13 am'), '2010-11-13T10:13:00Z', 'Month, dd"th", yyyy hh:mm "am"';
is f('Sun Nov 14 09:27:46 2010'), '2010-11-14T09:27:46Z', 'Dow Mon dd hh:mm:ss yyyy';
is f('16:22, November 12, 2010'), '2010-11-12T16:22:00Z', 'hh:mm, Monthname dd, yyyy';
is f('Yesterday, 06:44 PM'), '2008-03-04T18:44:00Z', '"Yesterday", hh:mm "PM"';

is f('Sat Nov 13 13:32:45 -0800 2010'), '2010-11-13T13:32:45-0800', 'Dow Mon dd hh:mm:ss -hhmm yyyy';
is f('Thu, Jun 10, 2010 at 11:28:40AM +0300'), '2010-06-10T11:28:40+0300', 'Dow, Mon dd, yyyy "at" hh:mm:ss"AM" +hhmm';
is f('12:29, 3 November 2010 (UTC)'), '2010-11-03T12:29:00Z', 'hh:mm, mm Monthname yyyy "(UTC)"';
is f('Fri 3 Dec 2010 @ 12:54:03 PM (EST)'), '2010-12-03T12:54:03-0500', 'Dow dd Mon yyyy @ hh:mm:ss "(EST)"';

# ------------------------------------------------------------

&f = { parse-datetime $^s, now => $d, :mdy };

is f('11/13 5:13PM'), '2007-11-13T17:13:00Z', 'mm/dd h:mm"PM"';
is f('10/30/2010 1:25:49 PM'), '2010-10-30T13:25:49Z', 'mm/dd/yyy h:mm:ss "PM"';
