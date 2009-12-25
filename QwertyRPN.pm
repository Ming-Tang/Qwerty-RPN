#!/usr/bin/perl
package Math::QwertyRPN;
require Exporter;
require 5.10.0;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Math::Trig qw(asin acos tan atan);
use constant PI => 3.14159265358979;
use POSIX qw(ceil floor);
use re 'eval';
use strict;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(eval_rpn shell);
our @EXPORT = qw(eval_rpn);
our $VERSION = '0.3.4';

our $rxnum = qr/(\d+(?:\.\d+)?)/;
our $rxgoto = qr/\<([A-Za-z0-9_]+)/;
our $rxget = qr/\$([A-Za-z0-9_]+)/;
our $rxgv = qr/\$\$/;
our $rxset = qr/\=([A-Za-z0-9_]+)/;
our $rxsv = qr/\=\$/;

sub eval_rpn($) {
  # init variables
  our $code = shift @_;
  $code =~ s/;.*?[\r\n]+//;
  our @tokens = ();
  $code =~ /^
            (?:
             ((?:\s|\r|\n)+   # whitespaces
             |\d+(?:\.\d+)?   # numbers
             |\>[A-Za-z0-9_]+ # labels
             |\<[A-Za-z0-9_]+ # goto statements
             |\$[A-Za-z0-9_]+ # get variables
             |\$\$            # variable-variables
             |\=[A-Za-z0-9_]+ # set variables
             |\=\$            # set variable-variables
             |.               # anything else
             )
             (?{push @tokens, $+})
            )*
            $/x;
  our %labels = { };
  our $i = 0;
  our $pointer = 0;

  # index GOTO labels
  $i ++, (/^\>([A-Za-z0-9_]+)$/ and $labels{$1} = $i) foreach @tokens;

  # runtime variables
  our @stack = ();
  our %variables = { };
  our $pc = 0;

  sub op(&) {
    $#stack < 1 and die 'Not enough operands.';
    my $sub = shift;
    my ($r, $l) = (pop @stack, pop @stack);
    push @stack, &$sub($l, $r);
  }
  sub un(&) {
    $#stack < 0 and die 'Stack is empty.';
    my $sub = shift;
    $stack[$#stack] = &$sub($stack[$#stack]);
  }
  sub factorial($) {
    my $n = 1;
    $n *= $_ for 2..shift;
    return $n;
  }
  sub avg() {
    my $sum = 0;
    my $len = $#stack;
    $sum += $_ foreach @stack;
    @stack = ();
    return $sum / $len;
  }
  sub deg($) {
    ((shift) / PI) * 180;
  }
  sub rad($) {
    ((shift) / 180) * PI;
  }
  sub round($) {
    my $n = shift;
    return int $n + 0.5 * ($n <=> 0);
  }
  sub log10($) {
    log(shift) / log(10);
  }
  sub bool($) {
    shift and return 1;
    return 0;
  }

  # main loop
  while ($_) {
    $_ = $tokens[$pc ++];
    # numbers
    /^$rxnum$/
                  and push @stack, $1 + 0;
    # goto statements
    /^$rxgoto$/   and do { return if $#stack < 0;
                           pop @stack and $pc = $labels{$1}; };
    # get variable
    /^$rxget$/    and push @stack, $variables{$1};
    # get variable-variables
    /^$rxgv$/     and do { die 'Not enough operands for variable-variable.' if $#stack < 0;
                           push @stack, $variables{pop @stack}; };
    # assign variables
    /^$rxset$/    and do { die 'Not enough operands for variable assignment.' if $#stack < 0;
                           $variables{$1} = pop @stack; };
    # assign variable-variables
    /^$rxsv$/     and do { die 'Not enough operands for variable-variable assignment.' if $#stack < 1;
                           my $l = pop @stack;
                           my $r = pop @stack;
                           $variables{$l} = $r; };

    # first row: 12345
    /^\~$/        and un { ~shift };
    /^\!$/        and pop @stack;
    /^\@$/        and push @stack, <STDIN> + 0;
    /^\#$/        and print 0 + pop @stack;
    /^\$$/        and do { $a = pop @stack;
                           $b = pop @stack;
                           push @stack, $a;
                           push @stack, $b; };
    /^\%$/        and op { (shift) % (shift) };
    /^\^$/        and op { (shift) ** (shift) };
    /^\&$/        and op { (shift) & (shift) };
    /^\*$/        and op { (shift) * (shift) };
    /^\($/        and un { (shift) - 1 };
    /^\)$/        and un { (shift) + 1 };
    /^_$/         and un { -shift };
    /^\+$/        and op { (shift) + (shift) };
    /^\`$/        and op { (shift) ^ (shift) };
    /^\-$/        and op { (shift) - (shift) };
    /^\=$/        and op { (shift) == (shift) };

    # second row: qwerty
    /^E$/         and un { 10 ** shift };
    /^R$/         and op { (shift) ** (1 / (shift)) };
    /^T$/         and un { atan shift @_ };
    /^\{$/        and op { (shift) << (shift) };
    /^\}$/        and op { (shift) >> (shift) };
    /^\|$/        and op { (shift) | (shift) };

    /^q$/         and un { (shift) ** 2 };
    /^e$/         and un { exp shift };
    /^r$/         and un { sqrt shift };
    /^t$/         and un { tan shift };
    /^p$/         and push @stack, PI;
    /^\[$/        and un { floor shift };
    /^\]$/        and un { ceil shift };
    /^\\$/        and un { round shift };

    # third row: asdfgh
    /^A$/         and push @stack, avg();
    /^D$/         and un { rad shift };
    /^S$/         and un { asin shift };
    /^L$/         and un { log10 shift };
    /^\:$/        and push @stack, $stack[$#stack];
    /^\"$/        and op { bool((shift) >= (shift)) };
    /^a$/         and un { abs shift };
    /^s$/         and un { sin shift };
    /^d$/         and un { deg shift };
    /^f$/         and un { factorial shift };
    /^l$/         and un { log shift };
    /^\'$/        and op { bool((shift) <= (shift)) };

    # fourth row: zxcvbnm
    /^X$/         and die '???';
    /^C$/         and un { acos shift };
    /^M$/         and op { my ($l, $r) = @_;
                           return ($l > $r) ? $l : $r; };
    /^\<$/        and op { bool((shift) < (shift)) };
    /^\>$/        and op { bool((shift) > (shift)) };
    /^\?$/        and push @stack, rand;

    /^x$/         and return @stack;
    /^c$/         and un { cos shift };
    /^b$/         and un { bool shift };
    /^n$/         and un { -shift };
    /^m$/         and op { my ($l, $r) = @_;
                           return ($l < $r) ? $l : $r; };
    /^\,$/        and push @stack, getc STDIN;
    /^\.$/        and print chr (0 + pop @stack);
    /^\/$/        and op { (shift) / (shift) };
  }
  return @stack;
}

sub shell() {
  print '>';
  while (<>) {
    eval { my @e = eval_rpn $_;
           @e and print join ', ', @e, "\n" };
    print "ERROR: $@" if $@;
    print ">";
  }
}

shell();
1;

__END__
=head1 NAME

QWERTY Reverse Polish Notation Calculator

=head1 SYNOPSIS

 use Math::QwertyRPN qw(eval_rpn);
 print eval_rpn "12 54 + 12 *"; # 792

A Reverse Polish notation calculator that has most opcodes of stack-based
assembly languages. It is generally Turing-complete (needs to be tested).

=head1 DESCRIPTION

The C<eval_rpn> function evaluates an expression. The first argument is a string
containing the expression. The function returns the stack after the evaluation.
When an error occurred, C<die> will be called. However, you can trap errors
by using C<eval>, C<do> or other try-catch modules.

An RPN expression contain a sequence of operations, they need to be
seperated by whitespaces or line breaks in some places,
to know more about Reverse Polish notation, read the article on
Wikipedia: L<http://en.wikipedia.org/wiki/Reverse_Polish_notation>.

To add a line comment, use C<;>. For example: C<< 1 1 + ; push 1 twice, and add them >>

The operators that do not exist in other RPN calculators include GOTO labels,
I/O and comparsion operators. To create a GOTO label, write C<< >label_name >>,
where C<label_name> is the name of the label.

The GOTO statement is like C<< >label_name >>. However, GOTO is conditional,
it is only made if the value on the top of stack is not 0 (zero). Also,
GOTO has a side effect of popping the stack.

C<< 12 3 <label >> will end up with 12 (instead of 12 3) on the stack.

Variables can be created and read by using the C<=> and C<$> operator.
To get a variable, write C<$name>, where C<name> is the
name of the variable. The value of that variable will be pushed
to the top of the stack.
To set a variable, write C<=name>. The stack will be popped.

For example, C<< 50 =value >> will set variable C<value> to 50. The stack
will end up empty because the 50 was popped to assign the variable.

You can read-write variables in the based on the value on the top of the stack
by using variable-variables. To read a variable-variable, use C<$$>.
The expression C<50 $$> pushes the value of variable C<50> to the stack.
The top of the stack will be popped
and it becomes the name of the variable-variable.

To write a variable-variable, write C<=$>. The top of the stack will be popped
and it becomes the name of the variable-variable.

The following expression outputs 10:

 10 ; stack:10
 5  ; stack:10 5
 =$ ;            variables:$5=10
 5  ; stack:5    variables:$5=10
 $$ ; stack:10   variables:$5=10

Arrays can be made by using variable-variables.
Variable-variables are made to make this language closer to Turing-complete.

=head2 ASSEMBLER to RPN

A typical stack-based assembly code looks like this:

 push 180  ; stack is 180
 push 250  ; stack is 180 250
 add       ; stack is 430
 push 50   ; stack is 430 50
 jeq LABEL ; jump if equals

It will be translated to RPN like this:

 180 250 + 50 = <LABEL

The PUSH opcode will be converted to numbers, and ADD will be converted
to C<+> as expected. However, there is no JEQ, JLT, JGT and other
compare-and-goto opcodes in RPN, so you must compare manually and goto.
C<50 = > means to compare the top of the stack with 50, and pushes 0 or 1
based on the result of the comparsion.

=head2 QUICK REFERENCE

Here is a list of all operators by order of QWERTY keyboard.
I don't have time to document all of them, so I used assembler opcode names.

 +--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+
 | ~ not  | ! pop  | @ getn | # putn | $ swap | % mod  | ^ pow  | & and  | * mul  | ( dec  | ) inc  | _ neg  | + add  |
 | ` xor  | 1 ---- | 2 ---- | 3 ---- | 4 ---- | 5 ---- | 6 ---- | 7 ---- | 8 ---- | 9 ---- | 0 ---- | - sub  | = eq   |
 +--------+--------+--------+--------+--------+--------+--------+--------+-----------------+--------+--------+--------+
 | Q      | W      | E 10^x | R root | T atan | Y      | U      | I      | O      | P      | { shl  | } shr  | | or   |
 | q x^2  | w      | e exp  | r sqrt | t tan  | y      | u      | i 1/x  | o      | p pi   | [ flr  | ] ceil | \ roun |
 +--------+--------+--------+--------+--------+--------+--------+--------+-----------------+--------+--------+--------+
 | A avg  | S asin | D rad  | F      | G      | H      | J      | K      | L log  | : dup  | " ge   |########|########|
 | a abs  | s sin  | d deg  | f fac  | g      | h      | j      | k      | l ln   | ;      | ' le   |########|########|
 +--------+--------+--------+--------+--------+--------+--------+--------+-----------------+--------+--------+--------+
 | Z      | X die  | C acos | V      | B      | N      | M max  | < lt   | > gt   | ? rand |########|########|########|
 | z      | x exit | c cos  | v      | b bool | n neg  | m min  | , getc | . putc | / div  |########|########|########|
 +--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+

Here is the list of other operations.

=over 7

=item 1

I<NUMBER>: Pushes a number to the stack.

=item 2

C<< < >>: Jumps to a label if the value on the top of the stack is not 0 (zero).
Example C<< <loop >>

=item 3

C<< > >>: Creates a label. Example: C<< >loop >>

=item 4

C<$>I<NAME>: Gets a variable. C<$var1> will push the value of C<var1>
on the top of the stack.

=item 5

C<=>I<NAME>: Sets a variable. C<12 =var1> will set C<var1> to 12, because
the item on the top of the stack is 12. Then 12 on the top of the stack will
be popped.

=item 6

C<$>I<NAME>: Gets a variable-variable.

=item 7

C<=$>Sets a variable-variable.

=back

=head1 EXAMPLES

Ask user to input 2 numbers, and print their sum.

 @@+#

Digital root calculator

 1@1-+9%

Locals-based factorial

 ;  CODE                ; PSEUDOCODE              
 @ =value               ; value = input_number();
 1 =result              ; result = 1;
 $value =i              ; i = value;
 >loop                  ; loop:
  $result $i * =result  ;  result *= i;
  $i ( =i $i            ;  i --;
 <loop                  ; if ($i) { goto loop; } 
 $result                ; return result;

without comments:

 @ =value 1 =result $value =i >loop $result $i * =result $i ( =i $i <loop $result

Countdown from 15

 16>loop(::#32.<loop!

=head1 TODO

=over 3

=item 1

Stack-based factorial example

=item 2

Support of subroutines/functions

=item 3

More detailed documentation

=cut

