```k
module SPEC-IDS
    imports BUILTIN-ID-TOKENS
    syntax Name ::= #LowerId [token, autoReject]
                  | #UpperId [token, autoReject]
endmodule
```

```k
module TYPING-TESTS-SPEC
    imports PLUTUS-CORE-TYPING
    imports SPEC-IDS
```

Kind Synthesis tests
====================

```k
    rule <kind> [ (con integer) (con 1) ]:Type => (type) </kind>
         <k> .K </k>

    rule <kind> (all s (size) s) => assertFailed((size):Kind == (type)) </kind>
         <k> .K </k>

    rule <kind> (all a (type) a) => (type) </kind>
         <k> .K </k>

    rule <kind> (all s (size) (fun [(con integer) s]
                                   (fun [(con integer) s]
                                        [(con integer) s])))
             => (type)
         </kind>
         <k> .K </k>

    rule <kind> (fun [ (con integer) (con 1) ] [ (con integer) (con 1) ])
             => (type)
         </kind>
         <k> .K </k>
```

Type Synthesis tests
====================

```k
    rule <k> (con 1 ! 5) => [ (con integer) (con 1) ]:Type </k>
         <kind> .K => _ </kind>

    rule <k> (lam x [(con integer) (con 1)] x)
          => (fun [ (con integer) (con 1) ] [ (con integer) (con 1) ])
         </k>
         <kind> .K => _ </kind>

    rule <k> [[{ (con addInteger) (con 1)} (con 1 ! 1)] (con 1 ! 1)]
          => [ (con integer) (con 1) ]:Type
         </k>
         <kind> .K => _ </kind>
```

```k
endmodule
```
