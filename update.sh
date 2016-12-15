#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

generated_warning() {
	cat <<-EOH
		#
		# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
		#
		# PLEASE DO NOT EDIT IT DIRECTLY.
		#

	EOH
}

travisEnv=
for version in "${versions[@]}"; do
	fullVersion="$(curl -sSL --compressed 'http://www.haproxy.org/download/'"$version"'/src/' | grep '<a href="haproxy-'"$version"'.*\.tar\.gz"' | sed -r 's!.*<a href="haproxy-([^"/]+)\.tar\.gz".*!\1!' | sort -V | tail -1)"
	md5="$(curl -sSL --compressed 'http://www.haproxy.org/download/'"$version"'/src/haproxy-'"$fullVersion"'.tar.gz.md5' | cut -d' ' -f1)"
	for variant in \
		debian \
		alpine \
	; do
		if [ "$variant" = 'debian' ]; then
			dir="$version"
		else
			dir="$version/$variant"
			variant="$(basename "$variant")"
		fi
		[ -d "$dir" ] || continue

		case "$version" in
			1.4|1.5) ;; # no support for Lua in these old versions
			*)
				template="Dockerfile-$variant.template"
				{ generated_warning; cat "$template"; } > "$dir/Dockerfile"
				( set -x; cp -a s6-* docker-entrypoint.sh "$dir" )
				;;
		esac

		(
			set -x
			sed -ri \
				-e 's/^(ENV HAPROXY_MAJOR) .*/\1 '"$version"'/' \
				-e 's/^(ENV HAPROXY_VERSION) .*/\1 '"$fullVersion"'/' \
				-e 's/^(ENV HAPROXY_MD5) .*/\1 '"$md5"'/' \
				"$dir/Dockerfile"
		)
	done
	
	for variant in alpine; do
		[ -d "$version/$variant" ] || continue
		( set -x; sed -ri "$sedExpr" "$version/$variant/Dockerfile" )
		travisEnv='\n  - VERSION='"$version VARIANT=$variant$travisEnv"
	done
	travisEnv='\n  - VERSION='"$version VARIANT=$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
