#!/bin/sh

# Recreate GitMe-$VERSION.exe

test -z "$1" && {
	echo "Usage: $0 <version>"
	exit 1
}

TARGET="$HOME"/GitMe-"$1".exe
TMPDIR=/tmp/installer-tmp
OPTS7="-m0=lzma -mx=9 -md=64M"
TMPPACK=/tmp.7z
SHARE=/share/GitMe

test ! -d "$TMPDIR" || rm -rf "$TMPDIR" || exit
mkdir "$TMPDIR" &&
cd "$TMPDIR" &&
(cd .. && test ! -f "$TMPPACK" || rm "$TMPPACK") &&
echo "Copying files" &&
cat "$SHARE"/fileList.txt | (cd / && tar -c --file=- --files-from=-) |
	tar xvf - &&
cat "$SHARE"/fileList-mingw.txt |
	(cd /mingw && tar -c --file=- --files-from=-) |
	tar xvf - &&
strip bin/*.exe &&
mkdir etc &&
cp "$SHARE"/gitconfig etc/ &&
cp "$SHARE"/setup-msysgit.sh ./ &&
echo "Creating archive" &&
cd .. &&
7z a $OPTS7 "$TMPPACK" installer-tmp &&
(cat /share/7-Zip/7zSD.sfx &&
 echo ';!@Install@!UTF-8!' &&
 echo 'Title="GitMe: MinGW Git + MSys installation"' &&
 echo 'BeginPrompt="This archive contains the minimal system needed to\nbootstrap the latest MinGW Git and MSys environment"' &&
 echo 'CancelPrompt="Do you want to cancel MSysGit installation?"' &&
 echo 'ExtractDialogText="Please, wait..."' &&
 echo 'ExtractPathText="Where do you want to install MSysGit?"' &&
 echo 'ExtractTitle="Extracting..."' &&
 echo 'GUIFlags="8+32+64+256+4096"' &&
 echo 'GUIMode="1"' &&
 echo 'InstallPath="C:\\msysgit"' &&
 echo 'OverwriteMode="2"' &&
 echo 'RunProgram="%%T\installer-tmp\bin\sh.exe /setup-msysgit.sh"' &&
 echo 'Delete="%%T\installer-tmp"' &&
 echo 'RunProgram="%%T\bin\sh.exe --login -i"' &&
 echo ';!@InstallEnd@!' &&
 cat "$TMPPACK") > "$TARGET" &&
echo Success! You\'ll find the new installer at $TARGET
rm $TMPPACK
