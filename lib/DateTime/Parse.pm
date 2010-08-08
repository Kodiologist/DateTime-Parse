module DateTime::Parse {

# ---------------------------------------------------------------
# Data
# ---------------------------------------------------------------

my %months =
    <jan feb mar apr may jun jul aug sep oct nov dec> Z 1 .. 12;

my %dows =
    <mo tu we th fr sa su> Z 1 .. 7;

my %special-names = yes => -1, tod => 0, tom => 1;
  # Yesterday, today, and tomorrow.

# ---------------------------------------------------------------
# Internal functions
# ---------------------------------------------------------------

sub in (Str $haystack, Str $needle) {
    $haystack.index($needle).defined
}

sub bm($b, $x) { $b ?? -$x !! $x }

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

    regex date_only { ^ <date> $ }

    token date {
        <special>                                         ||
        <next_last> <sep> <weekish>                       ||
        <weekish>   [<sep> <after_before>]?               ||
        [<dow> <sep>]?   [<ymd> || <md>]   [<sep> <dow>]?
    }
    
    token special { <specialname> <alpha>* }
    token specialname { yes || tod || tom }

    token weekish { week || <dow> }
    token dow { <downame> <alpha>* }
    token downame { mo || tu || we || th || fr || sa || su }

    token next_last { next || last }
    token after_before { after <sep> next || before <sep> last }
    
    token ymd {
         <yyyy> <sep> <an> <sep> <an> ||
           # A special case because the <an>s have to be
           # interpreted as (month, day) regardless of :mdy.
         <yyyy> <sep> <md>            ||
         <md>   <sep> <y>
    }

    token md {
         <an>    <sep> <an>    ||
         <mname> <sep> <d>     ||
         <d>     <sep> <mname> ||
         <dth>   <sep> <m>     ||
         <m>     <sep> <dth>
    }

    token y { \d\d(\d\d)? }
    token yyyy { \d**4 }

    token m { <mname> | \d\d? }
    token mname { <mon3> <alpha>* }
    token mon3
       { jan || feb || mar || apr || may || jun ||
         jul || aug || sep || oct || nov || dec }

    token d { (\d\d?) <th>? }
    token dth { (\d\d?) <th> }
    token th { st | nd | rd | th }

    token an { \d\d? }
      # Ambiguous number.

    token sep { <- alpha - digit>* }

}

class DateTime::Parse::G::Actions {
    has Date $.today = Date.today;
    has Int $.yy-center = $.today.year;
        # The year used to resolve two-digit year specifications.
    has Bool $.mdy;
    has Bool $.past;
    has Bool $.future;

    method new(*%_) {
        %_<past> and %_<future>
            and fail "DateTime::Parse: You can't specify both :past and :future";
        self.bless: *, |%_;
    }

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
            make Date.new: +$year, $month, $day;
    
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
        chars($year) == 2 and $year = min
           map({ $^n - $^n % 100 + $year },
               $.yy-center <<+<< (-100, 0, 100)),
           by => { abs $^n - $.yy-center };
        make Date.new: $year, $month, $day;
    }

    method md($/) {
    # "5th December"
        make $<an>
          ?? $.mdy
             ?? (+$<an>[0], +$<an>[1])
             !! (+$<an>[1], +$<an>[0])
          !! (($<m> || $<mname>).ast, +($<d> || $<dth>)[0])
    }

    method m($/) { make $<mname> ?? $<mname>.ast !! ~$/ }

    method mname($/) { make %months{~$<mon3>} }

}

# ----------------------------------------------------------------
# Exported functions
# ----------------------------------------------------------------

our sub parse-date(Str $s, *%_) is export {
    my $actions = DateTime::Parse::G::Actions.new: |%_;
    my $match = DateTime::Parse::G.parse(lc($s), :rule('date_only'), :actions($actions))
        or die "DateTime::Parse::parse-date: No parse: $s";
    $match<date>.ast;
}




}
