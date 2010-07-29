module DateTime::Parse {

my %months =
    <jan feb mar apr may jun jul aug sep oct nov dec> Z 1 .. 12;

my %dows =
    <mo tu we th fr sa su> Z 1 .. 7;

grammar StrDate {
    token TOP { ^ 
                  <special>                       ||
                  <dow>? <sep> <ymd> <sep> <dow>? ||
                  <md>                            ||
                  <dow>
                $
    }
    
    token special { <specialname> <alpha>* }

    token specialname { yes || tod || tom }
      # Yesterday, today, and tomorrow.

    token ymd {
         <yyyy>  <sep> <mon>   <sep> <d>     ||
         <an>    <sep> <an>    <sep> <y>     ||
         <d>     <sep> <mname> <sep> <y>     ||
         <y>     <sep> <mon>   <sep> <dth>   ||
         <y>     <sep> <d>     <sep> <mname> ||
         <y>     <sep> <dth>   <sep> <mon>   ||
         <mname> <sep> <d>     <sep> <y>
    }

    token md {
         <an>    <sep> <an>    ||
         <mname> <sep> <d>     ||
         <d>     <sep> <mname> ||
         <dth>   <sep> <mon>   ||
         <mon>   <sep> <dth>
    }

    token y { <yyyy> || \d\d }
    token yyyy { \d**4 }

    token mon { <mname> | <m> }
    token mname { <mon3> <alpha>* }
    token mon3
       { jan || feb || mar || apr || may || jun ||
         jul || aug || sep || oct || nov || dec }
    token m { \d\d? }

    token d { (\d\d?) <th>? }
    token dth { (\d\d?) <th> }
    token th { st | nd | rd | th }

    token an { \d\d? }
     # Ambiguous number.

    token dow { <downame> <alpha>* }
    token downame { mo || tu || we || th || fr || sa || su }
    
    token sep { <- alpha - digit>* }

}

sub next-with-dow(Date $date, Int $dow, Bool $backwards?) {
# Finds the nearest date with day of week $dow that's
#   later than or equal to $date     if $backwards is false   and
#   earlier than or equal to $date   if $backwards is true.
    my $s = $backwards ?? -1 !! 1;
    $date + $s * do $s * (7 + $dow - $date.day-of-week.Int) % 7
}

our sub parse-date(
        Str $s,
        Date :$today = Date.today,
        Int :$yy-center = $today.year,
          # The year used to resolve two-digit year specifications.
        Bool :$mdy,
        Bool :$past, Bool :$future,
    ) is export {

    $past and $future
        and fail "parse-date: You can't specify both :past and :future";

    my $match = StrDate.parse(lc $s)
        or fail "parse-date: No parse: $s";

    $match<special> and return
            $match<special><specialname> eq 'tod' ?? $today
        !!  $match<special><specialname> eq 'yes' ?? $today - 1
        !!                                           $today + 1;

    $match<dow> and not $match<ymd> and return next-with-dow
        $today, %dows{~$match<dow>[0]<downame>}, $past;

    my $in = $match<ymd>;

    my $year = $in<yyyy> || $in<y>;
    chars($year) == 2 and $year = min
        map({ $^n - $^n % 100 + $year },
            $yy-center <<+<< (-100, 0, 100)),
        by => { abs $^n - $yy-center };

    my ($month, $day);
    if $in<an> {
        $mdy ?? ($month, $day) !! ($day, $month) = @($in<an>);
    }
    else {
        $month = ~ do $in<mon> || $in<mname>;
        $month ~~ /<alpha>**3/ and $month = %months{~$/};
        $day = ($in<d> || $in<dth>)[0];
    }

    Date.new(+$year, +$month, +$day);

}

}
