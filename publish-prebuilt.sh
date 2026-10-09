#!/bin/bash -e

# Publish the .debs of every dcache slot from a local ./build.sh run as a GitHub
# release tagged with that slot's cache key, which build.sh then fetches instead
# of building. Userspace slots go to $PREBUILT_RELEASES as deb-<pkg>-<key>, the
# kernel to $KERNEL_RELEASES as kernel-<key>. Existing releases are left alone.

HERE=$(cd "$(dirname "$0")" && pwd); cd "$HERE"
KERNEL=x-chip-linux-deb

for slot in dcache/*/*/; do
    slot=${slot%/}
    pkg=$(basename "$(dirname "$slot")") key=$(basename "$slot")
    if [ "$pkg" = "$KERNEL" ]; then
        repo=${KERNEL_RELEASES:-anarkiwi/x-chip-linux-deb} tag="kernel-$key"
    else
        repo=${PREBUILT_RELEASES:-anarkiwi/x-chip-deb-repo} tag="deb-$pkg-$key"
    fi
    if gh release view "$tag" -R "$repo" >/dev/null 2>&1; then
        echo ">> $tag: exists in $repo"
        continue
    fi
    (cd "$slot" && sha256sum ./*.deb | sed 's# \./# #' > SHA256SUMS)
    gh release create "$tag" -R "$repo" --latest=false --title "$tag" \
        --notes "Prebuilt $pkg .debs for build.sh (dcache key $key)." \
        "$slot"/*.deb "$slot/SHA256SUMS"
    rm -f "$slot/SHA256SUMS"
    echo ">> $tag: published to $repo"
done
