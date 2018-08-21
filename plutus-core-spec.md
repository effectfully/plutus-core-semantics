Here, we define unit tests as reachability claims.

```k
module PLUTUS-CORE-SPEC
    imports PLUTUS-CORE
    imports PLUTUS-CORE-SYNTAX
```

Lambda Calculus
---------------

Basic application:

```k
rule <k> [ (lam x a x) (con 1 ! 1) ] => int(1, 1) </k>
     <env> .Map => .Map </env>
     <store> .Map => _ </store>
  [specification]

rule <k> [ (lam x a x) (con 1 ! 128) ] => (error (con (integer))) </k>
     <env> .Map => .Map </env>
     <store> .Map => _ </store>
  [specification]
 
rule <k> [ (lam y a x) (con 1 ! 1) ] => x ~> .Map </k>
     <env> .Map => _ </env>
     <store> .Map => _ </store>
  [specification]
```

Nested application:

```k
rule <k> [[(lam x a (lam y b x)) (con 1 ! 0)] (con 2 ! 123)] => int(1, 0) </k>
     <env> .Map => .Map </env>
     <store> .Map => _ </store>
  [specification]
```

Application uses capture-free substitution:

```k
rule <k> [ (lam x a (lam x b x)) (con 1 ! 1) ] => closure(_, x, x) </k>
     <env> .Map => .Map </env>
     <store> .Map => _ </store>
  [specification]
```

Integers & Integer arithmetic
-----------------------------

```k
rule <k> (con 1 ! 1     ) => int(1, 1)               </k>                           [specification]
rule <k> (con 1 ! 128   ) => (error (con (integer))) </k>                           [specification]
rule <k> (con 1 ! -128  ) => int(1, -128)            </k>                           [specification]
rule <k> (con 1 ! -129  ) => (error (con (integer))) </k>                           [specification]

rule <k> (con 2 !  32768) => (error (con (integer))) </k>                           [specification]
rule <k> (con 2 ! -32768) => int(2, -32768)          </k>                           [specification]
rule <k> (con 2 ! -32769) => (error (con (integer))) </k>                           [specification]
```

TODO: Could we used a specification of this form to show that this term must always
reduce completely (ideally we would be able to say "it must reduce to either a `BoundedInt` term
or an `Error` term).

```
rule <k> (con S ! V:Int) => C:KValue  </k>                                          [specification]
```

### Integer arithmetic

Addition:

```k
rule <k> [[(con addInteger) (con 1 ! 1) ] (con 1 ! 1) ] => (con 1 ! 2) </k>         [specification]
rule <k> [[(con addInteger) (con 1 ! 66)] (con 1 ! 66)] => (error (con (integer))) </k>
                                                                                    [specification]
```

Subtraction:

```k
rule <k> [[(con subtractInteger) (con 3 ! 10)] (con 3 ! 8) ] => (con 3 ! 2) </k>    [specification]
rule <k> [[(con subtractInteger) (con 3 ! 7)] (con 3 ! 10) ] => (con 3 ! -3) </k>   [specification]
rule <k> [[(con subtractInteger) (con 1 ! 66)] (con 1 ! -66) ] => (error (con (integer))) </k>
                                                                                    [specification]
```

Multiplication:

```k
rule <k> [[(con multiplyInteger) (con 3 ! 10)] (con 3 ! 8) ] => (con 3 ! 80) </k>   [specification]
rule <k> [[(con multiplyInteger) (con 1 ! 12)] (con 1 ! 11)] => (error (con (integer))) </k>
                                                                                    [specification]
```

Division:

```k
rule <k> [[(con divideInteger) (con 3 ! 10)] (con 3 ! 3) ] => (con 3 ! 3) </k>      [specification]
rule <k> [[(con divideInteger) (con 3 ! 0)] (con 3 ! 10) ] => (con 3 ! 0) </k>      [specification]
rule <k> [[(con divideInteger) (con 2 ! 66)] (con 2 ! 0) ] => (error (con (integer))) </k>
                                                                                    [specification]
```

Remainder:

```k
rule <k> [[(con remainderInteger) (con 3 ! 10)] (con 3 ! 3)] => (con 3 ! 1) </k>    [specification]
rule <k> [[(con remainderInteger) (con 3 ! 0)]  (con 3 ! 10)] => (con 3 ! 0) </k>   [specification]
rule <k> [[(con remainderInteger) (con 2 ! 66)] (con 2 ! 0) ] => (error (con (integer))) </k>
                                                                                    [specification]
```

Complex nested expressions:

```k
rule <k> [[(con addInteger) [[(con remainderInteger) (con 3 ! 10)] (con 3 ! 3)]]
                            [[(con multiplyInteger ) (con 3 ! 2 )] (con 3 ! 2)]
         ]
      => (con 3 ! 5)
    </k>
rule <k> [[(con addInteger) [[(con remainderInteger) (con 1 ! 10)] (con 1 ! 3)]]
                            [[(con multiplyInteger ) (con 1 ! 15 )] (con 1 ! 16)]
         ]
      => (error (con (integer)))
    </k>
rule <k> [[(con addInteger) [[(con remainderInteger) (con 3 ! 66)] (con 3 ! 0)]]
                            [[(con multiplyInteger ) (con 3 ! 2 )] (con 3 ! 2)]
         ]
      => (error (con (integer)))
    </k>
```

Less than:

```k
rule <k> [[(con lessThanInteger) (con 3 ! 10)] (con 3 ! 3)]  => #false </k>  [specification]
rule <k> [[(con lessThanInteger) (con 3 ! 3)] (con 3 ! 10)]  => #true </k>   [specification]
rule <k> [[(con lessThanInteger) (con 3 ! 10)] (con 3 ! 10)] => #false </k>  [specification]
```

Less than or equal to:

```k
rule <k> [[(con lessThanEqualsInteger) (con 3 ! 10)] (con 3 ! 3)]  => #false </k>  [specification]
rule <k> [[(con lessThanEqualsInteger) (con 3 ! 3)] (con 3 ! 10)]  => #true </k>   [specification]
rule <k> [[(con lessThanEqualsInteger) (con 3 ! 10)] (con 3 ! 10)] => #true </k>   [specification]
```

Greater than:

```k
rule <k> [[(con greaterThanInteger) (con 3 ! 10)] (con 3 ! 3)]  => #true </k>   [specification]
rule <k> [[(con greaterThanInteger) (con 3 ! 3)] (con 3 ! 10)]  => #false </k>  [specification]
rule <k> [[(con greaterThanInteger) (con 3 ! 10)] (con 3 ! 10)] => #false </k>  [specification]
```

Greater than or equal to:

```k
rule <k> [[(con greaterThanEqualsInteger) (con 3 ! 10)] (con 3 ! 3)]  => #true </k>   [specification]
rule <k> [[(con greaterThanEqualsInteger) (con 3 ! 3)] (con 3 ! 10)]  => #false </k>  [specification]
rule <k> [[(con greaterThanEqualsInteger) (con 3 ! 10)] (con 3 ! 10)] => #true </k>   [specification]
```

Equal to

```k
rule <k> [[(con equalsInteger) (con 3 ! 10)] (con 3 ! 3)]  => #false </k>  [specification]
rule <k> [[(con equalsInteger) (con 3 ! 3)] (con 3 ! 10)]  => #false </k>  [specification]
rule <k> [[(con equalsInteger) (con 3 ! 10)] (con 3 ! 10)] => #true </k>   [specification]
```

Resize integer

```k
rule <k> [[(con resizeInteger) (con 1)] (con 2 ! 100)] => (con 1 ! 100)           </k>  [specification]
rule <k> [[(con resizeInteger) (con 1)] (con 2 ! 128)] => (error (con (integer))) </k>  [specification]
```

Booleans & Unit
---------------

`#true`:

```k
rule  <k>[[ [[(con equalsInteger) (con 3 ! 3)] (con 3 ! 3)]
              (lam x a (con 3 ! 1))] (lam x a (con 3 ! 2))]
       => int(3, 1)
     </k>
     <env> .Map => .Map </env>
     <store> .Map => _ </store> [specification]
```

`#false`:

```k
rule  <k> [[ [[(con equalsInteger) (con 3 ! 3)] (con 3 ! 2)]
             (lam x a (con 3 ! 1))] (lam x a (con 3 ! 2))]
       => int(3, 2)
     </k>
     <env> .Map => .Map </env>
     <store> .Map => _ </store> [specification]
```

Bytestrings
-----------

```k
rule <k> (con 2 ! `0 )               => bytestring(2,      0 : nilBytes) </k>       [specification]
rule <k> (con 2 ! `00 )              => bytestring(2,      0 : nilBytes) </k>       [specification]
rule <k> (con 2 ! `0000 )            => bytestring(2, 0  : 0 : nilBytes) </k>       [specification]
rule <k> (con 2 ! `1000 )            => bytestring(2, 16 : 0 : nilBytes) </k>       [specification]
rule <k> (con 2 ! `00000 )           => (error (con (bytestring))) </k>             [specification]
rule <k> (con 8 ! `0123456789abcdef) => bytestring(8, 1 : 35 : 69 : 103 : 137 : 171 : 205 : 239 : nilBytes) </k> [specification]
```

Integer to ByteString

```k
rule <k> [[(con intToByteString) (con 1 )] (con 2 ! 100)]
      => bytestring(1 , 100 : nilBytes) </k>                                        [specification]
rule <k> [[(con intToByteString) (con 3)] (con 2 ! 100)]
      => bytestring(3, 0 : 0 : 100 : nilBytes) </k>                                 [specification]
rule <k> [[(con intToByteString) (con 5)] (con 2 ! 100)]
      => bytestring(5, 0 : 0 : 0 : 0 : 100 : nilBytes) </k>                         [specification]
rule <k> [[(con intToByteString) (con 1 )] (con 2 ! 999)]
      => (error (con (bytestring))) </k>                                            [specification]
```

TODO: The behaviour of converting negative integers to bytestrings is not specified:

```k
// rule <k> [[(con intToByteString) (con 3)] (con 2 ! -100)]
//       => bytestring(3, TODO_WHAT_GOES_HERE : 0 : 0 : nilBytes) </k>                                 [specification]
```

Concatentate:

```k
rule <k> [ [ (con concatenate) (con 2 ! `01  ) ]
                               (con 2 ! `03  ) ]
      => bytestring(2, 01 : 03 : nilBytes) </k>                                     [specification]
rule <k> [ [ (con concatenate) (con 2 ! `0102) ]
                               (con 2 ! `0304) ]
      => (error (con (bytestring))) </k>                                            [specification]
```

`takeByteString`
: returns the prefix of `xs` of length `n`, or `xs` itself if `n > length xs`. 

```k
rule <k> [[(con takeByteString) (con 1 ! 2)] (con 8 ! `0123456789abcdef)] 
      => bytestring(8, 1 : 35 : nilBytes)
     </k>                                                                           [specification]
rule <k> [[(con takeByteString) (con 1 ! 31)] (con 8 ! `0123456789abcdef)] 
      => bytestring(8, 1 : 35 : 69 : 103 : 137 : 171 : 205 : 239 : nilBytes)
     </k>                                                                           [specification]
rule <k> [[(con takeByteString) (con 1 ! 0)] (con 8 ! `0123456789abcdef)] 
      => bytestring(8, nilBytes)
     </k>                                                                           [specification]
// This is the observed Haskell behaviour for negative lengths.
rule <k> [[(con takeByteString) (con 1 ! -1)] (con 8 ! `0123456789abcdef)] 
      => bytestring(8, nilBytes)
     </k>                                                                           [specification]
```

Resize ByteString

```k
rule <k> [[(con resizeByteString) (con 3)] (con 5 ! `abcdef)]
      => bytestring (3, 171 : 205 : 239 : nilBytes ) </k>                           [specification]

rule <k> [[(con resizeByteString) (con 2)] (con 5 ! `abcdef)]
      => (error (con (bytestring))) </k>                                            [specification]
```

Equals (ByteStrings)

```k
rule <k> [[(con equalsByteString) (con 3 ! `abcd)]
                                  (con 3 ! `abcde)]
      => #false </k>                                                                [specification]

rule <k> [[(con equalsByteString) (con 3 ! `abcde)]
                                  (con 3 ! `abcd)]
      => #false </k>                                                                [specification]

rule <k> [[(con equalsByteString) (con 3 ! `abcd)]
                                  (con 3 ! `abcd)]
      => #true </k>                                                                 [specification]

rule <k> [[(con equalsByteString) (con 1 ! `abcd)]
                                  (con 1 ! `abcd)]
      => (error (con (bytestring))) </k>                                            [specification]
```

Recursion
---------

```comment
// Infinite loops currently
rule <k> [[#ycomb
           (lam f (dummyTy)
             (lam x (dummyTy)
               [[[#if [[(con equalsInteger) x] (con 3 ! 0)]]
                 (con 3 ! 1)]
                 [[(con multiplyInteger) x] [[(con subtractInteger) x] (con 3 ! 1)]]]
             )
           )
         ] (con 3 ! 0)]
      => int(3, 0) </k>                                                             [specification]
```

```k
endmodule
```
