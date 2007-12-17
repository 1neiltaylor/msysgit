#!/bin/sh

# We're already in the install directory
INSTALL_PATH="$(pwd)"
export PATH="$INSTALL_PATH/installer-tmp/bin:$PATH"

error () {
    echo "* error: $*"
    echo INSTALLATION ABORTED
    read -e IGNORED_INPUT
    trap - exit
    exit 1
}

echo -------------------------------------------------------
echo Checking environment
echo -------------------------------------------------------
type cygpath >/dev/null 2>/dev/null && {
    echo "Cygwin seems to be in your system path. This was detected"
    echo "by trying to run cygpath, which was found by this shell."
    echo ""
    echo "Cygwin may cause severe problems, like crashes, if used in"
    echo "combination with msysgit. Please remove Cygwin from you system"
    echo "PATH environment variable."
    echo ""
    echo "For assistance on how to control your environment variables"
    echo "you should consult Microsoft's knowlege base:"
    echo "   Windows XP: http://support.microsoft.com/kb/310519"
    echo "   Windows NT: http://support.microsoft.com/kb/100843"
    echo ""
    error "Can not install msysgit when Cygwin is in PATH."
}
echo "Environment is clean. Can install msysgit."

echo
echo -------------------------------------------------------
echo Fetching the latest MSys environment
echo -------------------------------------------------------
MSYSGIT_REPO_GIT=git://repo.or.cz/msysgit.git
MSYSGIT_REPO_GIT_MOB=ssh://mob@repo.or.cz/srv/git/msysgit.git
MSYSGIT_REPO_HTTP=http://repo.or.cz/r/msysgit.git

# Multiply git.exe

for builtin in init unpack-objects update-ref fetch ls-remote
do
	ln "$INSTALL_PATH/installer-tmp/bin/git.exe" \
		"$INSTALL_PATH/installer-tmp/bin/git-$builtin.exe"
done

git init &&
git config remote.origin.url $MSYSGIT_REPO_GIT &&
git config remote.origin.fetch \
	+refs/heads/@@MSYSGITBRANCH@@:refs/remotes/origin/@@MSYSGITBRANCH@@ &&
git config branch.master.remote origin &&
git config branch.master.merge refs/heads/@@MSYSGITBRANCH@@ &&
git config remote.mob.url $MSYSGIT_REPO_GIT_MOB &&
git config remote.mob.fetch +refs/remote/mob:refs/remotes/origin/mob &&
git config remote.mob.push master:mob &&

USE_HTTP=
git fetch ||
	USE_HTTP=t &&
        git config remote.origin.url $MSYSGIT_REPO_HTTP &&
        git fetch || {
		echo -n "Please enter a HTTP proxy: " &&
		read proxy &&
		test ! -z "$proxy" &&
		export http_proxy="$proxy" &&
		git fetch
	} ||
	error "Could not get msysgit.git"

git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

echo
echo -------------------------------------------------------
echo Checking out the master branch
echo -------------------------------------------------------
git-checkout -l -f -q -b master origin/@@MSYSGITBRANCH@@ ||
    error Couldn\'t checkout the master branch!


# TEMP: Remove pre-existing git directory
rm -rf git


echo
echo -------------------------------------------------------
echo Fetching the latest MinGW Git sources
echo -------------------------------------------------------

case "$USE_HTTP" in
t)
	GIT_REPO_URL=http://repo.or.cz/r/git.git/
	MINGW_REPO_URL=http://repo.or.cz/r/git/mingw.git/
	MINGW4MSYSGIT_REPO_URL=http://repo.or.cz/r/git/mingw/4msysgit.git/
;;
'')
	GIT_REPO_URL=git://repo.or.cz/git.git
	MINGW_REPO_URL=git://repo.or.cz/git/mingw.git
	MINGW4MSYSGIT_REPO_URL=git://repo.or.cz/git/mingw/4msysgit.git
;;
esac

git config submodule.git.url $MINGW4MSYSGIT_REPO_URL &&
mkdir git &&
cd git &&
git init &&
git config remote.junio.url $GIT_REPO_URL &&
git config remote.junio.fetch '+refs/heads/*:refs/remotes/junio/*' &&
git fetch junio &&
git config remote.mingw.url $MINGW_REPO_URL &&
git config remote.mingw.fetch '+refs/heads/*:refs/remotes/mingw/*' &&
git fetch mingw &&
git config remote.origin.url $MINGW4MSYSGIT_REPO_URL &&
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' &&
git fetch origin &&
if test -z "@@FOURMSYSGITBRANCH@@"
then
	FOURMSYS=$(cd .. && git ls-tree HEAD git |
		sed -n "s/^160000 commit \(.*\)	git$/\1/p")
else
	FOURMSYS=origin/@@FOURMSYSGITBRANCH@@
fi &&
git checkout -l -f -q $FOURMSYS ||
error Couldn\'t update submodule git!

echo
echo -------------------------------------------------------
echo Fetching HTML help pages
echo -------------------------------------------------------

cd .. &&
rm -rf /doc/git/html &&
git config submodule.html.url $GIT_REPO_URL &&
mkdir -p doc/git/html &&
cd doc/git/html &&
git init &&
git config remote.origin.url $GIT_REPO_URL &&
git config remote.origin.fetch '+refs/heads/html:refs/remotes/origin/html' &&
git fetch origin &&
git checkout -l -f -q $(cd ../../.. && git ls-tree HEAD doc/git/html |
	sed -n "s/^160000 commit \(.*\).doc\/git\/html$/\1/p") ||
error "Couldn't update submodule doc/git/html (HTML help will not work)."

