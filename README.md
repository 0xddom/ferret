# Ferret: A fuzzer for the ciaoengine binary

The [Ciao](https://ciao-lang.org) programming language has a virtual machine under the hood that in made in C. This fuzzer mutates a seed with radamsa and sends the samples as Ciao bytecode.

## Requirements

This fuzzer requires a working instalation of Ciao prolog and it's recomended to have one with some kind of instrumentation for detecting subtle bugs.

As an example this is how to build Ciao with `clang` and AddressSanitizer on:

```bash
./ciao-boot.sh configure \
	--core:custom-cc=clang \
	--core:extra-cflags="-fsanitize=address" \
	--core:extra-ldflags="-fsanitize=address"
./ciao-boot.sh build
```

For the mutation of the samples the fuzzer uses `radamsa`. For instalation instruction of `radamsa` check it's [repo](https://gitlab.com/akihe/radamsa).

## Usage

By default the fuzzer will use `camel.pl` as a seed file. This seed will usually crash the program and not even fuzz. To invoke the fuzzer run the `fuzzer.sh` script.

```bash
./fuzzer.sh # For fuzzing using camel.pl as seed
./fuzzer.sh <seed file> # For fuzzing with another file as seed
CIAOROOT=... ./fuzzer.sh # To change the directory where the fuzzer searchs for ciaoc.
```

To make a more intelligent fuzzing, either provide your own seed with the bytecode you want to test or use the `gen-hw-example.sh` script to generate the bytecode of a simple hello world program in Ciao Prolog.
