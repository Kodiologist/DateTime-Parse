module DateTime::Parse {

my %months =
    <jan feb mar apr may jun jul aug sep oct nov dec> Z 1 .. 12;

my %dows =
    <mo tu we th fr sa su> Z 1 .. 7;

grammar StrDate {
    token TOP { ^ [
        <special>                                         ||
        <next_last>  <sep>  <weekish>                     ||
        <weekish>   [<sep>  <after_before>]?              ||
        <dow>?       <sep>  <ymd_or_md>     <sep>  <dow>?
    ] $ }
    
    token special { <specialname> <alpha>* }

    token specialname { yes || tod || tom }
      # Yesterday, today, and tomorrow.

    token ymd_or_md { <ymd> || <md> }

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

    token weekish { week || <dow> }
    token dow { <downame> <alpha>* }
    token downame { mo || tu || we || th || fr || sa || su }

    token next_last { next || last }
    token after_before { after <sep> next || before <sep> last }
    
    token sep { <- alpha - digit>* }

}

sub bm($b, $x) { $b ?? -$x !! $x }
# bm($b, $x) is a shortcut for ($b ?? -1 !! 1) * $x

sub next-with-dow(Date $date, Int $dow, Bool $backwards?) {
# Finds the nearest date with day of week $dow that's
#   later than or equal to $date     if $backwards is false   and
#   earlier than or equal to $date   if $backwards is true.
    $date + bm $backwards,
        bm($backwards, (7 + $dow - $date.day-of-week.Int)) % 7
}

our sub parse-date(
        Str $s,
        Date :$today = Date.today,
        Int :$yy-center = $today.year,
          # The year used to resolve two-digit year specifications.
        Bool :$mdy,
        Bool :$past is copy, Bool :$future is copy,
    ) is export {

    $past and $future
        and fail "DateTime::Parse::parse-date: You can't specify both :past and :future";

    my $match = StrDate.parse(lc $s)
        or fail "DateTime::Parse::parse-date: No parse: $s";

    if $match<special> {
      # "Today" and the like.

        given ~ $match<special><specialname> {
            when 'yes' { $today - 1 }
            when 'tod' { $today }
            when 'tom' { $today + 1 }
        }

    } elsif $match<weekish> {
      # "Monday" or "Tuesday before last" or "next week".

        if ~ do $match<next_last> or $match<after_before> -> $s {
           $match<weekish> eq 'week' and return $today +
               bm $s ~~ /last/, do
               $match<after_before> ?? 14 !! 7;
           $past = ? do $s ~~ /last/;
        };
        ($match<after_before> ?? bm($past, 7) !! 0) +
            next-with-dow $today,
            %dows{~$match<weekish><dow><downame>},
            $past;

    } else {
       # "1994/07/03" or "5th December".
    
        my $in = $match<ymd_or_md><md> || $match<ymd_or_md><ymd>;
    
        my ($month, $day);
        if $in<an> {
            $mdy ?? ($month, $day) !! ($day, $month) = @($in<an>);
        }
        else {
            $month = ~ do $in<mon> || $in<mname>;
            $month ~~ /<alpha>**3/ and $month = %months{~$/};
            $day = ($in<d> || $in<dth>)[0];
        }
    
        my $year = $in<yyyy> || $in<y>;
        if $year {
            chars($year) == 2 and $year = min
                map({ $^n - $^n % 100 + $year },
                    $yy-center <<+<< (-100, 0, 100)),
                by => { abs $^n - $yy-center };
        } else {
            my $ty = $today.year;
            my $then = Date.new($ty, +$month, +$day);
            $year =
                   $past   && $then > $today ?? $ty - 1
               !!  $future && $then < $today ?? $ty + 1
               !!                               $ty;
        }
    
        Date.new(+$year, +$month, +$day);

    }
}

}
