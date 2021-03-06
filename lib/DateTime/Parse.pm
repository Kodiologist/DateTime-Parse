module DateTime::Parse;

use DateTime::Parse::TZ;

# ---------------------------------------------------------------
# Data
# ---------------------------------------------------------------

my %months =
    <jan feb mar apr may jun jul aug sep oct nov dec> Z 1 .. 12;

my %dows =
    <mo tu we th fr sa su> Z 1 .. 7;

my %special-names =
    yes => -1, tod => 0, tom => 1;
  # Yesterday, today, and tomorrow.

my %zones = DateTime::Parse::TZ::zones();

# ---------------------------------------------------------------
# Internal functions
# ---------------------------------------------------------------

sub in (Str $haystack, Str $needle) {
    $haystack.index($needle).defined
}

sub bm ($b, $x) { $b ?? -$x !! $x }

sub list-cmp (@a, @b) {
    for @a Z @b -> $a, $b {
        $a before $b and return -1;
        $a after $b and return 1;
    }
    return 0;
}

sub next-with-dow (Date $date, Int $dow, $backwards?) {
# Finds the nearest date with day of week $dow that's
#   later than $date     if $backwards is false   and
#   earlier than $date   if $backwards is true.
    $date + bm $backwards,
        bm($backwards, (7 + $dow - $date.day-of-week.Int)) % 7 || 7
}

sub consistency-check (%o) {
    (%o<timezone>.defined, %o<utc>, %o<local>).grep(?*).elems > 1
        and die "No more than one of :timezone, :utc, and :local is allowed";
    %o<past> and %o<future>
        and die "You can't specify both :past and :future";
}

sub set-yy-center (%o is rw) {
    %o<yy-center> //= %o<today>.year + do
         %o<past>   ?? -50
      !! %o<future> ?? +50
      !!               0;
}

# ----------------------------------------------------------------
# Grammar and actions
# ----------------------------------------------------------------

my grammar G {
# Note that parse-date and parse-datetime downcase all input
# before trying to parse it with this grammar.

    token TOP { ^ <datetime> $ }

    regex datetime {
        now                                 ||
        <date> <.sep> <time> <.sep> <yyyy>? ||
          # The <yyyy> is in case the time is after the month and
          # day but before the year (yuck). When it exists, we
          # ignore any year given in <date>.
        <time> <.sep> [<date> <zone>?]?
    }

    regex date_only { ^ <date> $ }

    token time { t? <tbody> <zone>? }

    token tbody {
        <noonmid>                                      ||
        <hour> <timetail>                              ||
        <hour> ':'? <minute> [':'? <sec>]? <timetail>?
    }

    token hour { \d\d? }

    token minute { \d\d }

    token sec { (\d\d) <subsec>? }
    token subsec { '.' (\d+) }

    token timetail { <.sep> (<.noonmid> || <.ampm>) }
    token noonmid { noon | midnight }
    token ampm { am | pm }

    token zone {
        <.- alnum - [\-:+,.]>*
        [<offset> || <zone_abbr>]
        <.sep>
          # The trailing <.sep> is for closing parentheses.
    }
    token offset { 'utc'? ('+' || '-' || '−') <hour> [':'? <minute>]? }
    token zone_abbr { (<alpha> ** 1..5) <?{%zones.exists: uc $0}> }

    token date {
        <special>                                             ||
        <next_last> <.sep>   <weekish>                        ||
        <weekish>   <.sep>   <after_before>?                  ||
        <.dow>?     <.sep>   [<ymd> || <md>]   <.sep> <.dow>?
    }
    
    token special { <specialname> <.alpha>* }
    token specialname { yes || tod || tom }

    token weekish { week || <dow> }
    token dow { <downame> <.alpha>* }
    token downame { mo || tu || we || th || fr || sa || su }

    token next_last { next || last }
    token after_before { after <.sep> next || before <.sep> last }
    
    token ymd {
         <yyyy> <.sep> <an> <.sep> <an> ||
           # A special case because the <an>s have to be
           # interpreted as (month, day) regardless of :mdy.
         <yyyy> <.sep> <md>            ||
         <md>   <.sep> <y>
    }

    token md {
         <an>    <.sep> <an>    ||
         <mname> <.sep> <d>     ||
         <d>     <.sep> <mname> ||
         <dth>   <.sep> <m>     ||
         <m>     <.sep> <dth>
    }

    token y { \d\d(\d\d)? }
    token yyyy { \d**4 }

    token m { <mname> | \d\d? }
    token mname { <mon3> <.alpha>* }
    token mon3 {
        jan || feb || mar || apr || may || jun ||
        jul || aug || sep || oct || nov || dec
    }

    token d { (\d\d?) <th>? }
    token dth { (\d\d?) <th> }
    token th { st | nd | rd | th }

    token an { \d\d? }
      # Ambiguous number.

    token sep { [' at ' || ' on ' || <- alnum - [:]>]* }

}

my class G::Actions {
    has DateTime $.now;
    has Date $.today;
    has $.timezone;
    has Int $.yy-center;
      # The year used to resolve two-digit year specifications.
    has Bool $.mdy;
    has Bool $.past;
    has Bool $.future;

    method datetime ($/) {
        $<time> or return make $.now;
        my $timezone =
            $<zone>
         ?? $<zone>[0].ast
         !! $<time><zone>[0]
         ?? $<time><zone>[0].ast
         !! $.timezone;
        my %t = $<time><tbody>.ast;
        my &dt = { DateTime.new: :$^date, |%t, :$timezone };
        $<yyyy> and return make dt $<date>[0].ast.clone: year => ~$<yyyy>;
        $<date> and return make dt $<date>[0].ast;
        # No $<date>, so we have to guess.
        my $cmp = list-cmp
            ($.now.hour, $.now.minute, $.now.second),
            (%t<hour>, %t<minute>, %t<second>);
        make
              $.past   ?? dt($.today - +($cmp == -1))
          !!  $.future ?? dt($.today + +($cmp == 1))
          !!  min (dt($.today + 1), dt($.today), dt($.today - 1)),
                  by => { abs $^dt.Instant - $.now.Instant };
    }

    method tbody ($/) { make {
        hour =>
            $<noonmid>
         ?? tt-hour(12, ~$<noonmid>)
         !! $<timetail>
         ?? tt-hour($<hour>.Int, ~$<timetail>[0][0])
         !! +$<hour>,
        minute => +$<minute>,
        second => $<sec> && +$<sec>[0]
    } }

    multi tt-hour (12, 'midnight') {  0 }
    multi tt-hour (12, 'noon')     { 12 }
    multi tt-hour (12, 'am')       {  0 }
    multi tt-hour ($n, 'am')       { $n }
    multi tt-hour (12, 'pm')       { 12 }
    multi tt-hour ($n, 'pm')       { 12 + $n }

    method sec ($/) { make $0 + do $<subsec> && $<subsec>[0].ast }
    method subsec ($/) { make $0 / 10**($0.chars) }

    method zone ($/) {
        make ($<offset> || $<zone_abbr>).ast
    }

    method offset ($/) {
        make bm ($0 ne '+'), [+]
            60 * 60 * $<hour>, (60 * $<minute>[0] if $<minute>)
    }

    method zone_abbr ($/) { make %zones{uc $/} }

    method date ($/) {
        
        if $<special> {

            make $<special>.ast;

        } elsif $<weekish> {
          # "Monday" or "Tuesday before last" or "next week".
    
            if ~ do $<next_last> or $<after_before> -> $s {
               $!past = in $s, 'last';
               $<weekish> eq 'week' and return make $.today +
                   bm $.past, $<after_before> ?? 14 !! 7;
            }
            make ($<after_before> ?? bm($.past, 7) !! 0) +
                next-with-dow $.today,
                %dows{~$<weekish><dow><downame>},
                $.past;
    
        } elsif $<ymd> {

           make $<ymd>.ast;

        } elsif $<md> {

            my ($month, $day) = @($<md>.ast);
            my $ty = $.today.year;
            my $then = Date.new: $ty, $month, $day;
            my $year =
                  $.past   ?? $ty - ($then > $.today)
              !!  $.future ?? $ty + ($then < $.today)
              !!  min ($ty + 1, $ty, $ty - 1), by =>
                      { abs $.today - Date.new: $^n, $month, $day }        
            make Date.new: $year, $month, $day;
    
        }

    }

    method special ($/) {
    # "Today" and the like.
        make $.today + %special-names{~$<specialname>}
    }

    method ymd ($/) {
    # "1994/07/03"
        my $year = + do $<yyyy> || $<y>;
        my ($month, $day) = $<an>
         ?? (+$<an>[0], +$<an>[1])
         !! @($<md>.ast);
        # Handle two-digit years.
        if chars($year) == 1|2 {
            my @ys =
                grep { abs($.yy-center - $^y) <= 50 },
                map { $^n - $^n % 100 + $year },
                $.yy-center «+« (-100, 0, 100);
            my &f = { ($^n, $.today.month, $.today.day) };
            # We use &list-cmp instead of Date comparison
            # in order to avoid problems with February 29.
            $.past and @ys .= grep:
                { list-cmp(f($.today.year), f($^n)) != -1 };
            $.future and @ys .= grep:
                { list-cmp(f($.today.year), f($^n)) != 1 };
            @ys or die "No possible century for two-digit year $year with {$.past ?? ':past' !! ':future'}, :today($.today), and :yy-center($.yy-center)";
            $year = min @ys, by => { abs $^n - $.yy-center };
        }
        make Date.new: $year, $month, $day;
    }

    method md ($/) {
    # "5th December"
        make $<an>
          ?? $.mdy
             ?? ($<an>[0], $<an>[1])
             !! ($<an>[1], $<an>[0])
          !! (($<m> || $<mname>).ast, ($<d> || $<dth>)[0])
    }

    method m ($/) { make $<mname> ?? $<mname>.ast !! ~$/ }

    method mname ($/) { make %months{~$<mon3>} }

}

# ----------------------------------------------------------------
# Exported functions
# ----------------------------------------------------------------

our sub parse-date (Str $s, *%_ is copy) is export {
    %_.exists('now') and die ':now not permitted; use :today instead';
    consistency-check %_;
    %_<timezone> //= %_<utc> ?? 0 !! $*TZ;
    %_<today> //= DateTime.now.in-timezone(%_<timezone>).Date;
    set-yy-center %_;
    my $actions = G::Actions.new: |%_;
      # $actions.now is left undefined; we don't need it.
    my $match = G.parse(lc($s), :rule<date_only>, :$actions)
        or die "No parse: $s";
    $match<date>.ast;
}

our sub parse-datetime (Str $s, *%_ is copy) is export {
    %_.exists('today') and die ':today not permitted; use :now instead';
    consistency-check %_;
    my $requested-tz = %_<timezone> // do
        %_<utc>   ?? 0
     !! %_<local> ?? $*TZ
     !!              Any;
    %_<timezone> //= $requested-tz // do
        %_<now>   ?? %_<now>.timezone
     !!              $*TZ;
    (%_<now> //= DateTime.now) .= in-timezone: %_<timezone>;
    %_<today> = %_<now>.Date;
    set-yy-center %_;
    my $actions = G::Actions.new: |%_;
    my $match = G.parse(lc($s), :$actions)
        or die "No parse: $s";
    my $dt = $match<datetime>.ast;
    $requested-tz.defined ?? $dt.in-timezone($requested-tz) !! $dt
}
