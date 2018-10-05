Syntax
======

We separate the parsing of `Name` tokens from the rest of the synax to reduce conflicts when
defining rules:

```k
require "substitution.k"

module PLUTUS-CORE-TYPING-SYNTAX
    imports PLUTUS-CORE-SYNTAX-BASE

    syntax Name ::= r"[a-zA-Z][a-zA-Z0-9_']*" [notInRules, token, autoReject]
                  | #LowerId                  [notInRules, token, autoReject]
                  | #UpperId                  [notInRules, token, autoReject]
endmodule
```

```k
module PLUTUS-CORE-COMMON
    imports INT
    imports BUILTIN-ID-TOKENS

    syntax Name

    // TODO: This should not allow negative integers
    syntax Size ::= Int
endmodule
```

```k
module PLUTUS-CORE-SYNTAX-TYPES
    imports PLUTUS-CORE-COMMON

    syntax TyVar ::= Name

    syntax TyBuiltinName ::= Name
                           | "integer" | "bytestring" | "size"

    syntax TyConstant ::= Size
                        | TyBuiltinName

    syntax Type ::= TyVar
                  | "(" "fun" Type Type ")"
                  | "(" "all" TyVar Kind Type ")"
                  | "(" "fix" TyVar Type ")"
                  | "[" Type Type "]" [seqstrict]
                  | TyValue

    syntax TyValue ::= "(" "fun" TyValue TyValue ")"
//                     | "(" "all" TyVar Kind TyValue ")"
                     | "(" "fix" TyVar TyValue ")"
                     | "(" "lam" TyVar Kind Type ")"
                     | "(" "con" TyConstant ")"
                     | NeutralTy

    syntax NeutralTy ::= TyVar
                       | "[" NeutralTy TyValue "]"

    syntax Kind ::= "(" "type" ")"
                  | "(" "Kfun" Kind Kind ")"
                  | "(" "size" ")"

    syntax Type ::= "(" "Kfun" Type Type ")"
endmodule
```

```k
module PLUTUS-CORE-SYNTAX-BASE
    imports PLUTUS-CORE-SYNTAX-TYPES

    syntax Var           ::= Name
    syntax BuiltinName   ::= Name

    syntax ByteString ::= r"\\#[a-fA-F0-9][a-fA-F0-9]*" [notInRules, token, autoReject]

    syntax BuiltinName   ::= BinaryBuiltin | UnaryBuiltin
    syntax UnaryBuiltin  ::= "sha2_256" | "sha3_256"
    syntax BinaryBuiltin ::= "addInteger"         | "subtractInteger"
                           | "multiplyInteger"    | "divideInteger"
                           | "remainderInteger"
                           | "lessThanInteger"    | "lessThanEqualsInteger"
                           | "greaterThanInteger" | "greaterThanEqualsInteger"
                           | "equalsInteger"
                           | "resizeInteger"
                           | "intToByteString"
                           | "concatenate"        | "takeByteString"
                           | "resizeByteString"   | "equalsByteString"

    syntax Version ::= r"[0-9]+(\\.[0-9]+)*" [token]

    syntax Constant ::= Size "!" Int
                      | Size "!" ByteString
                      | BuiltinName
                      | Size

    syntax Term ::= Var
                  | "(" "run" Term ")"
                  | "{" Term Type "}" [seqstrict]
                  | "(" "unwrap" Term ")"
                  | "[" Term Term "]" [seqstrict]
                  | "(" "error" Type ")"
                  | Value

    syntax Value ::= "(" "abs" TyVar Kind Value ")"
                   | "(" "wrap" TyVar Type Value ")"
                   | "(" "lam" Var Type Term ")"
                   | "(" "con" Constant ")"

    syntax Program ::= "(" "program" Version Term ")"
endmodule
```

Configuration
=============

```k
module PLUTUS-CORE-TYPES-CONFIGURATION
    syntax Program
    configuration <k> $PGM:Program </k>
                  <kind> .K </kind>

    syntax Type ::= "#hole"
endmodule
```

Kind Syntesis
=============

```k
module PLUTUS-CORE-KIND-SYNTHESIS
    imports PLUTUS-CORE-SYNTAX-TYPES
    imports PLUTUS-CORE-TYPES-CONFIGURATION
    imports DOMAINS
    imports SUBSTITUTION

    syntax KResult ::= Kind
    syntax KVariable ::= TyVar
    syntax Type ::= Kind

    // tyall
    rule <kind> (all A K TY) => TY[K/A] == (type) ... </kind>

    // tyfix
    //rule (fix A TY) => 

    // tyfun
    rule <kind> (fun TY1 TY2)      => TY1 ~> (fun #hole TY2)  ... </kind> requires notBool(isKind(TY1))
    rule <kind> (fun TY1:Kind TY2) => TY2 ~> (fun TY1 #hole)  ... </kind> requires notBool(isKind(TY2))
    rule <kind> TY1:Kind ~> (fun #hole TY2 ) => (fun TY1 TY2) ... </kind>
    rule <kind> TY2:Kind ~> (fun TY1  #hole) => (fun TY1 TY2) ... </kind>
    rule <kind> (fun (type) (type)) => (type) ... </kind>

    // tylam
    rule <kind> (lam A:TyVar K TY) => (Kfun K TY[K/A]) ... </kind>

    // seqstrict
    rule <kind> [ TY1 TY2 ]      => TY1 ~> [ #hole TY2 ] ... </kind> requires notBool(isKind(TY1))
    rule <kind> [ TY1:Kind TY2 ] => TY2 ~> [ TY1 #hole ] ... </kind> requires notBool(isKind(TY2))
    rule <kind> TY1:Kind ~> [ #hole TY2 ] => [ TY1 TY2 ] ... </kind>
    rule <kind> TY2:Kind ~> [ TY1  #hole] => [ TY1 TY2 ] ... </kind>
    // tyapp
    rule <kind> [ (Kfun K1:Kind K2:Kind) K1:Kind ] => K2 ... </kind>

    // tybuiltin
    rule <kind> (con integer) => (Kfun (size) (type)) ... </kind>
    rule <kind> (con S:Size) => ((size)):Kind ... </kind>

    syntax K ::= Type "==" Kind [strict(1)]
               | assertFailed(K)
    rule <kind> TY == K => TY ~> #hole == K ... </kind> requires notBool(isKind(TY))
    rule <kind> K1:Kind ~> #hole == K2 => K1 == K2 ... </kind>
    rule <kind> K:Kind == K => K ... </kind>
    rule <kind> K1:Kind == K2 => assertFailed(K1 == K2) ... </kind>
      requires K1 =/=K K2
endmodule
```

Typing
======

```k
module PLUTUS-CORE-TYPE-SYNTHESIS
    imports PLUTUS-CORE-SYNTAX-BASE
    imports PLUTUS-CORE-KIND-SYNTHESIS
    imports SUBSTITUTION
```

Program version has no semantic meaning:

```k
    rule (program V TM) => TM
```

```k
    syntax Term ::= Type

    syntax ResultType ::= TyValue
    syntax KResult ::= ResultType
    syntax Type ::= ResultType
    syntax KVariable ::= Var

    syntax Type ::= #type(Term) | #type(Type)
    rule #type(TY:Type) => TY [anywhere]

    // builtin
    rule (con S ! _:Int) => [ (con integer) (con S:Size):Type ]:Type
    syntax TyVar ::= "s"
    rule (con addInteger)
      => (all s (size)
           (fun [(con integer) s] (fun [(con integer) s] [(con integer) s])))
    rule isResultType([(con integer) (con _)]:Type) => true

    // lam
    rule (lam X:Var TY:Type TM:Term) => (fun TY #type(TM[TY/X]))

    // app
    rule isResultType((fun TY1:ResultType TY2:ResultType)) => true
    rule [(fun T1:Type T2:Type):Term T1:Type] => T2

    // inst

    // All cannot be reduced unless it is in { }. This is similar to how lambdas need to be turned
    // into closures.
    rule isResultType((all A:TyVar K TY)) => true

    rule <k> { TY1 TY2:Type } ... </k>
         <kind> .K => TY2 </kind>
    rule <k> { (all A:TyVar K TY1) TY2:Type } => TY1[TY2/A] ... </k>
         <kind> K:Kind => .K </kind>
endmodule
```

```k
module PLUTUS-CORE-TYPING
    imports PLUTUS-CORE-TYPE-SYNTHESIS
endmodule
```
