#!/bin/sh -e

cleanup() {
	rm -rf "$tmp"
}

tmp="$(mktemp -d)"
trap cleanup EXIT
chmod 0755 "$tmp"

arch="$(apk --print-arch)"
repositories_file=/etc/apk/repositories
keys_dir=/etc/apk/keys

while getopts "a:r:k:o:" opt; do
	case $opt in
	a) arch="$OPTARG";;
	r) repositories_file="$OPTARG";;
	k) keys_dir="$OPTARG";;
	o) outfile="$OPTARG";;
	esac
done
shift $(( $OPTIND - 1))

cat "$repositories_file"

if [ -z "$outfile" ]; then
	outfile=rootfs-$arch.tar.gz
fi

mkdir -p "$tmp"/usr/bin
mkdir -p "$tmp"/usr/lib
ln -s bin "$tmp"/sbin
ln -s bin "$tmp"/usr/sbin
ln -s usr/bin "$tmp"/bin
ln -s usr/lib "$tmp"/lib
${APK:-apk} add --keys-dir "$keys_dir" --no-cache \
	--repositories-file "$repositories_file" \
	--no-script --root "$tmp" --initdb --arch "$arch" \
	"$@"
for link in $("$tmp"/bin/busybox --list-full); do
	[ -e "$tmp"/$link ] || ln -s /bin/busybox "$tmp"/$link
done

# disable password login but allow login with ssh keys for root
sed -i -e 's/^root::/root:*:/' "$tmp"/etc/shadow

branch=edge
VERSION_ID=$(awk -F= '$1=="VERSION_ID" {print $2}'  "$tmp"/etc/os-release)
case $VERSION_ID in
*_alpha*|*_beta*) branch=edge;;
*.*.*) branch=v${VERSION_ID%.*};;
esac

cat > "$tmp"/etc/apk/repositories <<EOF
/home/mike/packages/main
EOF

tar --numeric-owner --exclude='dev/*' -c -C "$tmp" . | gzip -9n > "$outfile"
