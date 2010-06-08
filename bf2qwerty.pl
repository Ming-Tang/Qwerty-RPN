#!/usr/bin/perl
# Brainfk to Qwerty RPN translator
package Math::QwertyRPN::BF;

use strict;

my $label = 'a';
my @stack = ();

print '0=i';
while (<>) {
  my @chars = split //;
  for my $char(@chars) {
    if ($char eq '-') {
      print '$i$$($i=$';
    } elsif ($char eq '+') {
      print '$i$$)$i=$';
    } elsif ($char eq '<') {
      print '$i(=i';
    } elsif ($char eq '>') {
      print '$i)=i';
    } elsif ($char eq '[') {
      push @stack, $label;
      print ">$label";
      $label ++;
    } elsif ($char eq ']') {
      print '$i$$<' . (pop @stack);
    } elsif ($char eq ',') {
      print ',$i=$';
    } elsif ($char eq '.') {
      print '$i$$.';
    }
  }
}
print "\n";
1;

