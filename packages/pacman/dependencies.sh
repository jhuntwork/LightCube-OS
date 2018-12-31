#!/bin/bash
#
#   dependencies.sh - Warn about missing library dependencies
#
#   Copyright (c) 2017 Jeremy Huntwork <jhuntwork@lightcubesolutions.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

[[ -n "$LIBMAKEPKG_LINT_PACKAGE_DEPENDENCIES_SH" ]] && return
LIBMAKEPKG_LINT_PACKAGE_DEPENDENCIES_SH=1

LIBRARY=${LIBRARY:-'/share/makepkg'}

source "$LIBRARY/util/message.sh"


lint_package_functions+=('warn_dependencies')

list_file_dependencies() {
    if [ -z "$1" ] || [ ! -f "$1" ] ; then
        printf 'Must specify a file\n'
        return 1
    fi
    TMP=$(mktemp)
    local deps=''
    local badlink=0

    local lddout=$(ldd "$1" 2>"$TMP")
    if [ $? -ne 0 ] || grep -q 'No such file' "$TMP" || \
            grep -q 'symbol not found' "$TMP" ; then
        badlinks=1
    fi

    local IFS=$'\n'
    for i in $lddout ; do
        local dep=$(printf '%s\n' "$i" | awk '{print $3}')
        [ -z "$dep" ] && continue
        case "$dep" in
            ldd|$(pwd)*)
                ;;
            *) deps=$(printf '%s\n%s\n' "$dep" "$deps")
                ;;
        esac
    done
    printf '%s\n' "$deps"
    rm "$TMP"
    [ $badlinks -eq 1 ] && return 1
}

collect_all_lib_dependencies() {
    if [ -z "$1" ] || [ ! -d "$1" ] ; then
        printf 'Must specify a directory\n'
        return 1
    fi

    local alldeps=''
    local badlinks=0

    for file in $(find "$1" -type f) ; do
        ft=$(file -b "$file")
        case "$ft" in
            ELF*dynamic*)
                deps=$(LD_LIBRARY_PATH="${1}/lib" list_file_dependencies "$file")
                [ $? -ne 0 ] && badlinks=1
                alldeps=$(printf '%s\n%s\n' "$deps" "$alldeps")
                ;;
            *)
                ;;
        esac
    done
    printf '%s\n' "$alldeps" | sort -u
    [ $badlinks -eq 1 ] && return 1
}

warn_dependencies() {
    local badlinks=0
    local pkg_deps=$(collect_all_lib_dependencies "$pkgdir")
    local not_found=()
    [ $? -ne 0 ] && badlinks=1
    if [ $badlinks -eq 1 ] ; then
	    error 'Package contains libraries with unresolvable symbols'
        return 1
    fi
    if [ -n "$depends" ] ; then
        msg2 "$(gettext "Defined dependency: %s")" "${depends[@]}"
    fi
    for lib in $pkg_deps; do
        local found=0
        dep="$(pacman -Qoq ${lib})"
        for pkg in "${depends[@]}" ; do
            [ "$dep" = "$pkg" ] && found=1
        done
        if [ $found -eq 0 ] ; then
            not_found+=("$dep")
        fi
    done
    if [ -n "$not_found" ] ; then
        error "$(gettext "Missing dependency: %s")" "${not_found[@]}"
        printf '%s\n' "${not_found[@]}" >>"/tmp/missingdeps.${pkgname}"
        return 2
    fi
}
