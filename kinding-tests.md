```k
module SPEC-IDS
    imports BUILTIN-ID-TOKENS
    syntax Name ::= #LowerId [token, autoReject]
                  | #UpperId [token, autoReject]
endmodule
```

``` {.k}
module TYPING-TESTS-SPEC
    imports PLUTUS-CORE-TYPING
    imports SPEC-IDS

    rule [ (con integer) (con 1) ]
      => (type)

    rule (all s (size) s) => assertFailed((size):Kind == (type))
    rule (all a (type) a) => (type)

    rule (all s (size) (fun [(con integer) s] (fun [(con integer) s] [(con integer) s])))                        
      => (type)
      
//    rule (con addInteger) => (type)
//    
//    rule (fun [ (con integer) (con 1) ] [ (con integer) (con 1) ])
//      => (type)
endmodule
```

