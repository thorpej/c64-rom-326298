#!/bin/sh -
#       
# Copyright (c) 2023 Jason R. Thorpe.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#       
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

#
# mkflashimg --
#
# Create a flash ROM image for the c64-rom-326298 ROM replacer board.
#

default_outfile="c64-rom-326298.bin"
outfile=$default_outfile

progname=`basename $0`

KERNAL_0="empty"
KERNAL_1="empty"
KERNAL_2="empty"
KERNAL_3="empty"
KERNAL_count=0

BASIC_0="empty"
BASIC_1="empty"
BASIC_2="empty"
BASIC_3="empty"
BASIC_count=0

Character_0="empty"
Character_1="empty"
Character_2="empty"
Character_3="empty"
Character_count=0

image_types="KERNAL BASIC Character"

help()
{
	cat >&2 <<USAGEMESSAGE

usage: $progname -k kernal.bin -b basic.bin -c char.bin [outfile]
       $progname -h                         # display this message (help)

At least one each KERNAL, BASIC, and Character ROM image must be
specified, up to a limit of 4 each.  Each time a particular image
type is specified, the next slot for that image type will be used.
To insert a blank ROM image in the next slot for that image type,
use the special image name "empty".

If not specified, the default output file name is '$default_outfile'.

USAGEMESSAGE
}

usage()
{
	help
	exit 1
}

size_for_img_type()
{
	case $1 in
	Character)		echo 4096 ;;
	*)			echo 8192 ;;
	esac
}

check_file_size()
{
	# $1 = image name
	# $2 = image type

	local size
	local typesize

	typesize=$(size_for_img_type $2)

	if [ x"$1" != xempty ]; then
		if [ ! -f "$1" -o ! -r "$1" ]; then
			echo "Unable to read file: '$1'" >&2
			exit 1
		fi

		size=$(stat -L -f %z "$1")
		if [ x"$size" != x"$typesize" ]; then
			echo "File must be $typesize bytes: '$1'" >&2
			exit 1
		fi
	fi
}

add_kernal()
{
	if [ $KERNAL_count -ge 4 ]; then
		usage
	fi

	check_file_size "$1" KERNAL

	var=KERNAL_$KERNAL_count
	KERNAL_count=$((KERNAL_count + 1))
	eval "$var=\"$1\""
}

add_basic()
{
	if [ $BASIC_count -ge 4 ]; then
		usage
	fi

	check_file_size "$1" BASIC

	var=BASIC_$BASIC_count
	BASIC_count=$((BASIC_count + 1))
	eval "$var=\"$1\""
}

add_character()
{
	if [ $Character_count -ge 4 ]; then
		usage
	fi

	check_file_size "$1" Character

	var=Character_$Character_count
	Character_count=$((Character_count + 1))
	eval "$var=\"$1\""
}

emit_image()
{
	# $1 = img type
	# $2 = img num

	local fname
	local fvar
	local typesize

	fvar="\$${1}_${2}"
	eval "fname=$fvar"

	typesize=$(size_for_img_type $1)

	if [ x"$fname" = xempty ]; then
		dd if=/dev/zero bs=$typesize count=1 >> "$outfile" 2> /dev/null
	else
		cat $fname >> "$outfile"
	fi
}

emit_image_type()
{
	# $1 = img type

	local num

	num=0

	while [ $num -lt 4 ]; do
		emit_image $1 $num
		num=$((num + 1))
	done
}

check_image_type()
{
	# $1 image type

	local num
	local num_empty
	local fname
	local fvar

	num=0
	num_empty=0

	while [ $num -lt 4 ]; do
		fvar="\$${1}_${num}"
		eval "fname=$fvar"
		echo "${fvar}='$fname'"
		if [ x"$fname" = xempty ]; then
			num_empty=$((num_empty + 1))
		fi
		num=$((num + 1))
	done

	if [ $num_empty -eq 4 ]; then
		echo "Must specify at least one $1 image." >&2
		exit 1
	fi
}

check_image_types()
{
	local imgtype

	for imgtype in $image_types; do
		check_image_type $imgtype
	done
}

build_flash_image()
{
	local imgtype

	rm -f "$outfile"
	touch "$outfile"

	for imgtype in $image_types; do
		emit_image_type $imgtype
	done
}

while getopts b:c:hk: opt; do
	case $opt in
	b)	add_basic "$OPTARG" ;;
	c)	add_character "$OPTARG" ;;
	k)	add_kernal "$OPTARG" ;;
	h)	help; exit 0 ;;
	\?)	usage ;;
	esac
done
shift $((OPTIND - 1))

if [ x"$1" != x ]; then
	outfile="$1"
	shift 1
fi

if [ x"$1" != x ]; then
	usage
fi

check_image_types

echo ""
env echo -n "Write flash image to '$outfile' (y/n)? "

read response
case "$response" in
[yY] | [yY][eE][sS])	;;
*)			echo "Aborting!"; exit 0 ;;
esac

build_flash_image

echo ""
env ls -l "$outfile"

exit 0
