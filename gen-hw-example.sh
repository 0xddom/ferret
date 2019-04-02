#!/usr/bin/env bash

###############################################################
#
# Generates the bytecode of a hello world program for ciao 
# prolog. This bytecode can be used as seed for the fuzzer.
#
###############################################################

if [ -z $CIAOROOT ]; then
	>&2 echo "You need to set the CIAOROOT environment variable to that the fuzzer can find the prolog environment"
	exit 1
fi
ciaoc=$CIAOROOT/build/bin/ciaoc

hw=`mktemp`
hwout=`mktemp`
out=${1:-hw.bytecode}

cat > $hw <<EOF
:- module(_,[main/1]).

% Compile this example with 'ciaoc hw.pl', which produces the 'hw'
% executable.

main(_) :-
	write('Hello world!'), nl.
EOF

$ciaoc -o $hwout $hw 
tail -n +6 $hwout > $out