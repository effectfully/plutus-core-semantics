#!/usr/bin/env python3

from kninja import *
import sys

# Helpers
#
class Plutus(KProject):
    def __init__(self):
        super().__init__(builddir = '.build')
        self.include('lib/build.ninja')
        self.testdir = '$builddir/t/'
        self.java    = self.kdefinition( name    = 'plutus-core-java'
                                       , main    = self.tangleddir('plutus-core.k')
                                       , backend = 'java'
                                       , alias   = 'spec-java'
                                       )
        self.ocaml   = self.kdefinition_no_build( name             = 'plutus-core-ocaml'
                                                , kompiled_dirname = 'plutus-core-kompiled'
                                                , alias            = 'spec-ocaml'
                                                )
        self.java_typing = self.kdefinition( name    = 'typing-java'
                                           , main    = self.tangleddir('typing.k')
                                           , backend = 'java'
                                           , alias   = 'typing-java'
                                           )

    def test_exec(self, input):
        expected = input + '.expected'
        self.java.krun_and_check ('$builddir/t/', input, expected)
        self.ocaml.krun_and_check('$builddir/t/', input, expected, krun_flags = '--interpret')

    def test_exec_ocaml(self, input):
        expected = input + '.ocaml.expected'
        self.ocaml.krun_and_check('$builddir/t/', input, expected, krun_flags = '--interpret')

    def test_exec_java(self, input):
        expected = input + '.java.expected'
        self.java.krun_and_check('$builddir/t/', input, expected)

    def test_typing(self, input):
        expected = input + '.typing.expected'
        self.java_typing.krun_and_check('$builddir/t/', input, expected)

plutus = Plutus()

# Basic tests
# -----------
#
# Since the OCaml does not support reachability claims (even
# concrete ones) these also function as smoke tests for the OCaml backend)
#
plutus.test_exec('t/builtin-app.plc')
plutus.test_typing('t/builtin-app.plc')

# We need distinct exptected and actual files for these.
plutus.test_exec_ocaml('t/bytestring.plc')
plutus.test_exec_java('t/bytestring.plc')

# Cryptography
# ------------
#
# We do not yet support hashing on the Java backend since the SHA3 hook does
# not exist, and the SHA2 hook is missing an alias into the HASH namespace.
#
plutus.test_exec_ocaml('t/sha2.plc')
# plutus.test_exec_java('t/sha2.plc')
plutus.test_exec_ocaml('t/sha3.plc')
# plutus.test_exec_java('t/sha3.plc')

# Complex tests
# -------------
#
# These are tests involving recursion, and other tests from the Roman and the
# IOHK Plutus team.
#
plutus.test_exec('t/sum-to-10.plc')
plutus.test_exec('t/11-scott-to-int.plc')
plutus.test_exec('t/if-then-else.plc')
plutus.test_exec('t/sum-list.plc')
