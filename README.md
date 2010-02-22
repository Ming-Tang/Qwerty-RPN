# SYNOPSIS

    use Math::QwertyRPN qw(eval_rpn);
     print eval_rpn "12 54 + 12 *"; # 792

A Reverse Polish notation calculator that has most opcodes of stack-based assembly languages. It is generally Turing-complete (needs to be tested).

# DESCRIPTION

The `eval_rpn` function evaluates an expression. The first argument is a string containing the expression. The function returns the stack after the evaluation. When an error occurred, `die` will be called. However, you can trap errors by using `eval`, `do` or other try-catch modules.

An RPN expression contain a sequence of operations, they need to be seperated by whitespaces or line breaks in some places, to know more about Reverse Polish notation, read the article on Wikipedia: [http://en.wikipedia.org/wiki/Reverse\_Polish\_notation][1].

To add a line comment, use `;`. For example: `1 1 + ; push 1 twice, and add them`

The operators that do not exist in other RPN calculators include GOTO labels, I/O and comparsion operators. To create a GOTO label, write `>label_name`, where `label_name` is the name of the label.

The GOTO statement is like `>label_name`. However, GOTO is conditional, it is only made if the value on the top of stack is not 0 (zero). Also, GOTO has a side effect of popping the stack.

`12 3 <label` will end up with 12 (instead of 12 3) on the stack.

Variables can be created and read by using the `=` and `$` operator. To get a variable, write `$name`, where `name` is the name of the variable. The value of that variable will be pushed to the top of the stack. To set a variable, write `=name`. The stack will be popped.

For example, `50 =value` will set variable `value` to 50. The stack will end up empty because the 50 was popped to assign the variable.

You can read-write variables in the based on the value on the top of the stack by using variable-variables. To read a variable-variable, use `$$`. The expression `50 $$` pushes the value of variable `50` to the stack. The top of the stack will be popped and it becomes the name of the variable-variable.

To write a variable-variable, write `=$`. The top of the stack will be popped and it becomes the name of the variable-variable.

The following expression outputs 10:

     10 ; stack:10
     5  ; stack:10 5
     =$ ;            variables:$5=10
     5  ; stack:5    variables:$5=10
     $$ ; stack:10   variables:$5=10

Arrays can be made by using variable-variables. Variable-variables are made to make this language closer to Turing-complete.

## ASSEMBLER to RPN

A typical stack-based assembly code looks like this:

     push 180  ; stack is 180
     push 250  ; stack is 180 250
     add       ; stack is 430
     push 50   ; stack is 430 50
     jeq LABEL ; jump if equals

It will be translated to RPN like this:

     180 250 + 50 = <LABEL

The PUSH opcode will be converted to numbers, and ADD will be converted to `+` as expected. However, there is no JEQ, JLT, JGT and other compare-and-goto opcodes in RPN, so you must compare manually and goto. `50 = ` means to compare the top of the stack with 50, and pushes 0 or 1 based on the result of the comparsion.

## QUICK REFERENCE

Here is a list of all operators by order of QWERTY keyboard. I don't have time to document all of them, so I used assembler opcode names.

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

1.  *NUMBER*: Pushes a number to the stack.

2.  `<`: Jumps to a label if the value on the top of the stack is not 0 (zero). Example `<loop`

3.  `>`: Creates a label. Example: `>loop`

4.  `$`*NAME*: Gets a variable. `$var1` will push the value of `var1` on the top of the stack.

5.  `=`*NAME*: Sets a variable. `12 =var1` will set `var1` to 12, because the item on the top of the stack is 12. Then 12 on the top of the stack will be popped.

6.  `$`*NAME*: Gets a variable-variable.

7.  `=$`Sets a variable-variable.

# EXAMPLES

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

# TODO

1.  Stack-based factorial example

2.  Support of subroutines/functions

3.  More detailed documentation

 [1]: http://en.wikipedia.org/wiki/Reverse_Polish_notation
