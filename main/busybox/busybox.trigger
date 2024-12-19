#!/bin/sh

do_bb_install=

for i in "$@"; do
	case "$i" in
		/lib/modules/* | /usr/lib/modules/*)
			# don't run busybox depmod if we have kmod installed
			# we dont need to run it twice.
			target=$(readlink -f "$(command -v depmod || true)")
			if [ -d "$i" ] && [ "$target" = "/usr/bin/busybox" ]; then
				/usr/bin/busybox depmod ${i#*/lib/modules/}
			fi
			;;
		*) do_bb_install=yes;;
	esac
done

if [ -n "$do_bb_install" ]; then
	[ -e /usr/bin/bbsuid ] && /usr/bin/bbsuid --install
	[ -e /usr/bin/busybox-extras ] && /usr/bin/busybox-extras --install -s
	/usr/bin/busybox --install -s
fi
