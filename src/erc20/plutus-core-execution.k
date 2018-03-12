require "../syntax.k"
require "../hex-conversion.k"
require "../execution/plutus-core-execution.k"

module PLUTUS-ERC20-SYNTAX
  imports ERC20
  imports PLUTUS-CORE-SYNTAX

  syntax Dec ::= "test.preamble" "(" ")" [macro]
               | "test.allowances" "(" Tm ")" [prefer, strict]

  syntax Def ::= "test.makeBalance" "(" TmDef ")" [prefer, strict]
               | "test.makeCaller" "(" TmDef ")" [prefer, strict]
               | "test.makeTotalSupply" "(" TmDef ")" [prefer, strict]
               | "test.totalSupply" "(" ")" [prefer, strict]               
               | "test.balanceOf" "(" TmDef ")" [prefer, strict]
               | "test.allowance" "(" TmDef "," TmDef ")" [prefer, strict]
               | "test.approve" "(" TmDef "," TmDef ")" [prefer, strict]
               | "test.transfer" "(" TmDef "," TmDef ")" [prefer, strict]
               | "test.transferFrom" "(" TmDef "," TmDef "," TmDef ")" [prefer, strict]
endmodule

module PLUTUS-CORE-EXECUTION
  imports PLUTUS-ERC20-SYNTAX
  imports PLUTUS-CORE-EXEC-REDUCTIONS

  configuration
    <PLUTUS>
      initERC20Cell(Init)  // including the ERC20-K configuration.
      // <k> $PGM:Prg </k>
      <lenv> .Map </lenv>
      <genv> .Map </genv>
      <mod> .ModName </mod>
      <in> .List </in>
      <out> .List </out>
      <throwAsPrint> ERCFalse:ERCBool </throwAsPrint> // for print THROW
      <printStrings> ERCTrue:ERCBool </printStrings>  // for tests
    </PLUTUS>

  /***************************************************************************/
  /************************   ERC 20 CONSTRUCTS   ****************************/
  /***************************************************************************/

  // ---PREAMBLE----------
  // This preamble creates some initial configuration:
  //   accounts, allowances, supply, caller.
  // Recall that this ERC20 semantics assumes that the total supply, all the
  // accounts and all their allowances (including those which are 0), as well
  // as the caller given.  Then the code is executed on the caller's behalf.

  rule test.preamble() =>

    makeAccount(10,100)
    makeAccount(9,90)
    makeAccount(8,80)
    makeAccount(7,70)
    makeAccount(6,60)
    makeAccount(5,50)
    makeAccount(4,40)
    makeAccount(3,30)
    makeAccount(2,20)
    makeAccount(1,10)

    test.allowances(10)
    test.allowances(9)
    test.allowances(8)
    test.allowances(7)
    test.allowances(6)
    test.allowances(5)
    test.allowances(4)
    test.allowances(3)
    test.allowances(2)
    test.allowances(1)

    makeTotalSupply(550)
    (declare caller integer)
    (define caller 7)
    makeCaller((#stringToModName("Foo") . caller):QualN)
    makeThrowAsPrintTrue

  rule test.allowances(I:Int) =>

    makeAllowance(I,10)
    makeAllowance(I,9)
    makeAllowance(I,8)
    makeAllowance(I,7)
    makeAllowance(I,6)
    makeAllowance(I,5)
    makeAllowance(I,4)
    makeAllowance(I,3)
    makeAllowance(I,2)
    makeAllowance(I,1)

  // Next we define the special "make" constructs which create and modify the
  // ERC20-K state.  One should be careful with these constructs, because any
  // mistake can make ERC20-K behave unexpectedly.  Such operations should not
  // exist in normal implementations of languages for smart contracts.

  rule <k> makeAccount(A,V) => .K ...</k>
       <accounts>... .Bag => <account> <id> A </id> <balance> V </balance> </account> ...</accounts>
       <allowances>... .Bag => <allowance> <owner> A </owner> <spenders> .Bag </spenders> </allowance> ...</allowances>
  rule <k> makeAllowance(A,B) => .K ...</k> <owner> A </owner>
       <spenders>... .Bag => <allow> <spender> B </spender> <amount> 0 </amount> </allow> ...</spenders>
  rule <k> makeTotalSupply(I) => .K ...</k> <supply> _ => I </supply> requires I >=Int 0
  rule <k> makeCaller(I:Int) => .K ...</k> <caller> _ => I </caller>
  rule <k> makeBalance(I:Int) => .K ...</k> <caller> Owner </caller> <id> Owner </id> <balance> _ => I </balance>
  rule <k> makeThrowAsPrintTrue  => .K ...</k> <throwAsPrint> _ => ERCTrue </throwAsPrint>
  rule <k> makeThrowAsPrintFalse => .K ...</k> <throwAsPrint> _ => ERCFalse </throwAsPrint>
  rule <k> throw => ERCFalse ...</k> <throwAsPrint> ERCTrue </throwAsPrint> <out>... .List => ListItem("THROW\n") </out>
  rule <k> makePrintStringsTrue  => .K ...</k> <printStrings> _ => ERCTrue  </printStrings>
  rule <k> makePrintStringsFalse => .K ...</k> <printStrings> _ => ERCFalse </printStrings>


  syntax K ::= "out" "(" TmDef ")" [prefer, strict]
  rule <k> out(V:Val) => .K ... </k>
       <out> ... .List => ListItem(V) </out>

  rule test.makeBalance(Value:TmDef) => makeBalance(Value)
  rule test.makeCaller(Id:TmDef) => makeCaller(Id)
  rule test.makeTotalSupply(Value:TmDef) => makeTotalSupply(Value)

  rule test.totalSupply() => out(totalSupply())
  rule test.balanceOf(Id:TmDef) => out(balanceOf(Id))
  rule test.allowance(Owner, Spender) => out(allowance(Owner, Spender))
  rule test.approve(Spender, Allowance) => out(approve(Spender, Allowance))
  rule test.transfer(To, Value) => out(transfer(To, Value))
  rule test.transferFrom(From, To, Value) => out(transferFrom(From, To, Value))

endmodule
