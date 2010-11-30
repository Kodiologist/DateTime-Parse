module DateTime::Parse;

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

# ---------------------------------------------------------------
# Internal functions
# ---------------------------------------------------------------

sub in (Str $haystack, Str $needle) {
    $haystack.index($needle).defined
}

sub bm($b, $x) { $b ?? -$x !! $x }

sub list-cmp(@a, @b) {
    for @a Z @b -> $a, $b {
        $a before $b and return -1;
        $a after $b and return 1;
    }
    return 0;
}

sub next-with-dow(Date $date, Int $dow, $backwards?) {
# Finds the nearest date with day of week $dow that's
#   later than $date     if $backwards is false   and
#   earlier than $date   if $backwards is true.
    $date + bm $backwards,
        bm($backwards, (7 + $dow - $date.day-of-week.Int)) % 7 || 7
}

# ----------------------------------------------------------------
# Grammar and actions
# ----------------------------------------------------------------

grammar DateTime::Parse::G {

    token TOP { ^ <datetime> $ }

    regex datetime { <date> <.sep> <time>    ||
                     <time> [<.sep> <date>]? }

    regex date_only { ^ <date> $ }

    token time {
        <noonmid>                                            ||
        <hour> <timetail>                                    ||
        <hour> <.tsep> <minute> [<.tsep> <sec>]? <timetail>?
    }

    token hour { \d\d? }

    token minute { \d\d }

    token sec { (\d\d) <subsec>? }
    token subsec { '.' (\d+) }

    token timetail { <.sep> (<.noonmid> || <.ampm>) }
    token noonmid { noon | midnight }
    token ampm { am | pm }

    token tsep { ':' }

    token date {
        <special>                                             ||
        <next_last> <.sep> <weekish>                          ||
        <weekish>   [<.sep> <after_before>]?                  ||
        [<.dow> <.sep>]?   [<ymd> || <md>]   [<.sep> <.dow>]?
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
    token mon3
       { jan || feb || mar || apr || may || jun ||
         jul || aug || sep || oct || nov || dec }

    token d { (\d\d?) <th>? }
    token dth { (\d\d?) <th> }
    token th { st | nd | rd | th }

    token an { \d\d? }
      # Ambiguous number.

    token sep { <- alpha - digit - tsep>* }

}

class DateTime::Parse::G::Actions {
    has DateTime $.now;
    has Date $.today;
    has $.timezone;
    has Int $.yy-center = $.today.year;
      # The year used to resolve two-digit year specifications.
    has Bool $.mdy;
    has Bool $.past;
    has Bool $.future;

    method new(*%_) {
        %_<past> and %_<future>
            and fail "You can't specify both :past and :future";
        self.bless: *, |%_;
    }

    method datetime ($/) {
        $<date> and return make DateTime.new:
            date => $<date>[0].ast, |($<time>.ast), :$.timezone;
        # No $<date>, so we have to guess.
        my %t = $<time>.ast;
        my $cmp = list-cmp
            ($.now.hour, $.now.minute, $.now.second),
            (%t<hour>, %t<minute>, %t<second>);
        my &f = { DateTime.new: :$^date, |%t, :$.timezone };
        make
              $.past   ?? f($.today - +($cmp == -1))
          !!  $.future ?? f($.today + +($cmp == 1))
          !!  min (f($.today + 1), f($.today), f($.today - 1)),
                  by => { abs $^dt.Instant - $.now.Instant };
    }

    method time ($/) { make {
        hour =>
            $<noonmid>
         ?? tt-hour(12, ~$<noonmid>)
         !! $<timetail>
         ?? tt-hour($<hour>.Int, ~$<timetail>[0][0])
         !! $<hour>,
        minute => $<minute>,
        second => $<sec> && $<sec>[0].ast
    } }

    multi tt-hour(12, 'midnight') {  0 }
    multi tt-hour(12, 'noon')     { 12 }
    multi tt-hour(12, 'am')       {  0 }
    multi tt-hour($n, 'am')       { $n }
    multi tt-hour(12, 'pm')       { 12 }
    multi tt-hour($n, 'pm')       { 12 + $n }

    method sec ($/) { make $0 + do $<subsec> && $<subsec>[0].ast }
    method subsec ($/) { make $0 / 10**($0.chars) }

    method date($/) {
        
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

    method special($/) {
    # "Today" and the like.
        make $.today + %special-names{~$<specialname>}
    }

    method ymd($/) {
    # "1994/07/03"
        my $year = + do $<yyyy> || $<y>;
        my ($month, $day) = $<an>
         ?? (+$<an>[0], +$<an>[1])
         !! @($<md>.ast);
        # Handle two-digit years.
        if chars($year) == 1|2 {
            my @ys =
                map { $^n - $^n % 100 + $year },
                $.yy-center «+« (-100, 0, 100);
            my &f = { ($^n, $.today.month, $.today.day) };
            # We use &list-cmp instead of Date comparison
            # in order to avoid problems with February 29.
            $.past and @ys .= grep:
                { list-cmp(f($.today.year), f($^n)) != -1 };
            $.future and @ys .= grep:
                { list-cmp(f($.today.year), f($^n)) != 1 };
            @ys or die "No possible century for two-digit year $year with {$.past ?? ':past' !! ':future'}, :now($.now), and :yy-center($.yy-center)";
            $year = min @ys, by => { abs $^n - $.yy-center };
        }
        make Date.new: $year, $month, $day;
    }

    method md($/) {
    # "5th December"
        make $<an>
          ?? $.mdy
             ?? ($<an>[0], $<an>[1])
             !! ($<an>[1], $<an>[0])
          !! (($<m> || $<mname>).ast, ($<d> || $<dth>)[0])
    }

    method m($/) { make $<mname> ?? $<mname>.ast !! ~$/ }

    method mname($/) { make %months{~$<mon3>} }

}

# ----------------------------------------------------------------
# Exported functions
# ----------------------------------------------------------------

our sub parse-date(Str $s, *%_ is copy) is export {
    %_.exists('now') and die ':now not permitted; use :today instead';
    %_<local> and %_<utc> and die "You can't specify both :local and :utc";
    %_<timezone> //= %_<utc> ?? 0 !! $*TZ;
    %_<today> //= DateTime.now.in-timezone(%_<timezone>).Date;
    my $actions = DateTime::Parse::G::Actions.new: |%_;
      # $actions.now is left undefined; we don't need it.
    my $match = DateTime::Parse::G.parse(lc($s), :rule<date_only>, :actions($actions))
        or die "No parse: $s";
    $match<date>.ast;
}

our sub parse-datetime(Str $s, *%_ is copy) is export {
    %_.exists('today') and die ':today not permitted; use :now instead';
    %_<local> and %_<utc> and die "You can't specify both :local and :utc";
    %_<timezone> //=
        %_<utc>   ?? 0
     !! %_<local> ?? $*TZ
     !! %_<now>   ?? %_<now>.timezone
     !!              $*TZ;
    (%_<now> //= DateTime.now) .= in-timezone: %_<timezone>;
    %_<today> = %_<now>.Date;
    my $actions = DateTime::Parse::G::Actions.new: |%_;
    my $match = DateTime::Parse::G.parse(lc($s), :actions($actions))
        or die "No parse: $s";
    $match<datetime>.ast;
}
