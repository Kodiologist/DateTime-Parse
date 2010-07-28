# module DateTime::Parse;

my %months =
    <jan feb mar apr may jun jul aug sep oct nov dec> Z
    1 .. 12;

grammar StrDate {
    token TOP { ^ <dow>? <sep> <absolute> <sep> <dow>? $ }
    
    token absolute {
         <yyyy>  <sep> <mon>   <sep> <d>     ||
         <an>    <sep> <an>    <sep> <y>     ||
         <d>     <sep> <mname> <sep> <y>     ||
         <y>     <sep> <mon>   <sep> <dth>   ||
         <y>     <sep> <d>     <sep> <mname> ||
         <y>     <sep> <dth>   <sep> <mon>   ||
         <mname> <sep> <d>     <sep> <y>
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

our sub parse-date(
        Str $s,
        Date :$today = Date.today,
        Int :$yy-center = $today.year,
          # The year used to resolve two-digit year specifications.
          # prefer-past, prefer-future should also figure into this.
        Bool :$mdy
    ) is export {

    my $match = StrDate.parse(lc $s)
        or fail "parse-date: No parse: $s";
    my $in = $match<absolute>;

    my $year = $in<yyyy> || $in<y>;
    chars($year) == 2 and $year = min
        map({ $^n - $^n % 100 + $year },
            $yy-center «+« (-100, 0, 100)),
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
