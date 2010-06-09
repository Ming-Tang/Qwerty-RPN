#!/usr/bin/perl
require 5.10.0;

use Math::Trig qw(asin acos tan atan);
use constant PI => 3.14159265358979;
use POSIX qw(ceil floor);
use re 'eval';
use strict;

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
  while ($pc < $#tokens) {
    $_ = $tokens[$pc ++];
    # numbers
    /^$rxnum$/
                  and push @stack, $1 + 0;
    # goto statements
    /^$rxgoto$/   and do { return if $#stack < 0;
                           pop @stack and $pc = $labels{$1}; };
    # get variable
    /^$rxget$/    and push @stack, 0 + $variables{$1};
    # get variable-variables
    /^$rxgv$/     and do { die 'Not enough operands for variable-variable.' if $#stack < 0;
                           push @stack, 0 + $variables{pop @stack}; };
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
    /^X$/         and die join ', ' @stack;
    /^C$/         and un { acos shift };
    /^M$/         and op { my ($l, $r) = @_;
                           return ($l > $r) ? $l : $r; };
    /^\<$/        and op { bool((shift) < (shift)) };
    /^\>$/        and op { bool((shift) > (shift)) };
    /^\?$/        and push @stack, rand;

    /^x$/         and return @stack;
    /^c$/         and un { cos shift };
    /^b$/         and un { bool shift };
    /^m$/         and op { my ($l, $r) = @_;
                           return ($l < $r) ? $l : $r; };
    /^\,$/        and push @stack, ord getc STDIN;
    /^\.$/        and print chr (0 + pop @stack);
    /^\/$/        and op { (shift) / (shift) };
  }

  return @stack;
}

if (grep { /-s|--shell/ } @ARGV) {
  print STDERR '>';
  while (<STDIN>) {
    eval { my @e = eval_rpn $_;
           @e and print join ', ', @e, "\n" };
    print STDERR "ERROR: $@" if $@;
    print STDERR '>';
  }
} else {
  my $code;
  $code .= $_ while <>;
  eval { my @e = eval_rpn $code;
         @e and print STDERR join ', ', @e };
  die "ERROR: $@" if $@;
}

