#!/usr/bin/env bash

###############################################################
#
# Ferret: A fuzzer for ciao prolog bytecode.
# Requires a ciao prolog instalation and radamsa. 
# Look at README.md for details on usage and instalation.
#
###############################################################


seed=${1:-camel.pl}
tmplimit=1000
waiting=`mktemp -d`
queue=`mktemp -d`
crashes=crashes
newfiles=100
system=`uname`


if [ -z $CIAOROOT ]; then
	>&2 echo "You need to set the CIAOROOT environment variable to that the fuzzer can find the prolog environment"
	exit 1
fi
ciaoc=$CIAOROOT/build/bin/ciaoc

echo "Checking if radamsa is installed"
if ! which radamsa > /dev/null; then
	>&2 echo "You need to have radamsa installed. Check https://gitlab.com/akihe/radamsa for building instructions"
	exit 1
fi
echo "Radamsa is installed!"

function getmd5 {
	if [ "$system" == "Darwin" ]; then
		md5 "$1" | cut -f2 -d= | tr -d ' '
	else
		>&2 echo "Dunno how to get the md5 hash in this system."
		exit 1
	fi
}

function testsample {
	bytecode=$1
	header=$2
	sample=`mktemp`
	cat $header $bytecode > $sample
	chmod +x $sample
	$sample > /dev/null 
	if [ $? -gt 127 ]; then
		printf "\nCrashing input!\n"
		md5=`getmd5 $bytecode`
		cp $bytecode $crashes/$md5
		return 1
	fi
	return 0
}

mkdir -p $crashes

echo "Testing if I can get the md5..."
getmd5 $seed > /dev/null
echo "MD5 works!"

echo "Generating a hello world prolog example"
hw=`mktemp`
hwout=`mktemp`

cat > $hw <<EOF
:- module(_,[main/1]).

% Compile this example with 'ciaoc hw.pl', which produces the 'hw'
% executable.

main(_) :-
	write('Hello world!'), nl.
EOF

$ciaoc -o $hwout $hw 
$hwout > /dev/null

if [ $? != 0 ]; then
	>&2 echo "Failed to run the hello world program. Check that your prolog install works first"
	exit 1
fi
header=`mktemp`
cat $hwout | head -n 5 > $header

echo "Prolog works!"
echo "Testing the seed file $seed"

if ! testsample $seed $header; then
	>&2 echo "The seed crashed the program. Maybe you should use another seed..."
	exit 1
fi

while true; do
	echo "Generating a new set of $newfiles samples"
	prefix=`hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random`
	radamsa -n $newfiles -o "$queue/$prefix-sample-%n.%s" $seed `find $waiting`
	echo -n "Testing the samples"
	for sample in `ls $queue`; do
		echo -n '.'
		testsample $queue/$sample $header
	done
	echo
	cp $queue/* $waiting
	rm -f $queue/*
	waitinglen=`ls $waiting | wc -l`
	if [ $waitinglen -gt $tmplimit ]; then
		echo "Culling the oldest files in the waiting queue"
		rm `ls -rt $waiting | head -n $(($tmplimit / 2)) | sed "s|^|$waiting/|"`
	fi
done
