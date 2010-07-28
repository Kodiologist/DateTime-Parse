use v6;
use Test;
use DateTime::Parse;

plan *;

sub d ($y, $m, $d) { Date.new($y, $m, $d) }
sub p ($s, *%_) { ~ parse-date($s, |%_) }

is p('1994 12 6'),        '1994-12-06', 'yyyy mm dd';
is p('1994  12   6'),     '1994-12-06', 'yyyy mm dd (with spaces)';
is p('1994  12  06'),     '1994-12-06', 'yyyy mm dd (with spaces and leading 0)';
is p('06  12 1994'),      '1994-12-06', 'dd mm yyyy';
is p('06/12/1994'),       '1994-12-06', 'dd/mm/yyyy';
is p('19941206'),         '1994-12-06', 'yyyymmdd';

my $today = d(1997, 7, 7);
sub t ($s, *%_) { ~ parse-date($s, :$today, |%_) }

is t('6 12 94'),       '1994-12-06', 'dd mm yy';
is p('6 12 94', today => d(1942, 7, 7)), '1894-12-06', 'dd mm yy (different :today, 1)';
is p('6 12 94', yy-center => 1942), '1894-12-06', 'dd mm yy (:yy-center, 1)';
is p('6 12 94', today => d(2055, 7, 7)), '2094-12-06', 'dd mm yy (different :today, 2)';
is p('6 12 94', yy-center => 2055), '2094-12-06', 'dd mm yy (:yy-center, 2)';
is t('6/12/94'),       '1994-12-06', 'dd/mm/yy';
is t('6-12-94'),       '1994-12-06', 'dd-mm-yy';
is t('12 6 94', :mdy), '1994-12-06', 'mm dd yy';
is t('12/6/94', :mdy), '1994-12-06', 'mm/dd/yy';
is t('12-6-94', :mdy), '1994-12-06', 'mm-dd-yy';

is p('06 Dec 1994'),         '1994-12-06', 'dd Mon yyyy';
is p('6 December 1994'),     '1994-12-06', 'dd Monthname yyyy';
is p('6th December, 1994'),  '1994-12-06', 'dd"th" Monthname, yyyy';
is p('1st December 1994'),   '1994-12-01', 'dd"st" Monthname yyyy';
is p('2nd December 1994'),   '1994-12-02', 'dd"nd" Monthname yyyy';
is p('3rd December 1994'),   '1994-12-03', 'dd"rd" Monthname yyyy';
is p('Dec 6 1994'),          '1994-12-06', 'Mon dd yyyy';
is p('December 06, 1994'),   '1994-12-06', 'Monthname dd, yyyy';
is p('December 6th, 1994'),  '1994-12-06', 'Monthname dd"th" yyyy';
is p('1994 Dec 6'),          '1994-12-06', 'yyyy Mon dd';
is p('1994 6 Dec'),          '1994-12-06', 'yyyy dd Mon';

is t('6 December 94'), '1994-12-06', 'dd Monthname yy';
is t('Dec 6 94'),      '1994-12-06', 'Mon dd yy';

# Ignore the day of week when the month and day are given.

is p('1994 12 6 Fr'),        '1994-12-06', 'yyyy mm dd Dow';
is p('1994 12 6 Friday'),    '1994-12-06', 'yyyy mm dd Dayofweek';
is p('Fr 1994 12 6'),        '1994-12-06', 'Dow yyyy mm dd';
is p('Friday, 1994 12 6'),   '1994-12-06', 'Dayofweek, yyyy mm dd';
is t('Fr, 6 December 94'),   '1994-12-06', 'Dow, dd Monthname yy';

done_testing;
