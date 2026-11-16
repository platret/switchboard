#!/bin/zsh
# Builds Switchboard.app with the host inside it and packs it into a drag-to-Applications disk image.
#
#   apple/Scripts/make-dmg.sh [--adhoc-all]
#
# Output: apple/build/Switchboard-<version>-arm64.dmg. Everything the script builds stays under
# apple/build. Downloads are cached in ~/Library/Caches/switchboard-build.
#
# --adhoc-all  Sign node and claude ad hoc too. By default they keep the Developer ID signatures
#              their vendors notarized them with, and only unsigned code is signed ad hoc.
#
# Needs: Xcode, xcodegen, pnpm with `pnpm install` done in the repo, uvx (for dmgbuild), curl.
set -euo pipefail

# Node.js 24 LTS. Newest v24 release that was at least two weeks old when this was pinned
# (v24.22.2, released 2026-10-27). Update both lines together.
NODE_VERSION=24.22.2
NODE_DIST=https://nodejs.org/dist/v$NODE_VERSION
# dmgbuild from PyPI, run through uvx.
DMGBUILD_VERSION=1.6.7

adhoc_all=false
for argument in "$@"; do
  case $argument in
    --adhoc-all) adhoc_all=true ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) print -u2 "Unknown option: $argument"; exit 2 ;;
  esac
done

scripts=${0:A:h}
apple=${scripts:h}
repo=${apple:h}
build=$apple/build
cache=$HOME/Library/Caches/switchboard-build
stage=$build/stage
host=$stage/Host
app_out=$build/dist/Switchboard.app

step() { print -P "\n%B==> $*%b" }
fail() { print -u2 "error: $*"; exit 1 }

[[ $(uname -m) == arm64 ]] || fail "This script builds the arm64 app and has to run on Apple silicon."
for tool in curl shasum tar xcodebuild codesign ditto hdiutil pnpm; do
  command -v $tool >/dev/null || fail "$tool is not installed."
done
xcodegen=$(command -v xcodegen || true)
[[ -n $xcodegen ]] || { [[ -x /opt/homebrew/bin/xcodegen ]] && xcodegen=/opt/homebrew/bin/xcodegen } || fail "xcodegen is not installed (brew install xcodegen)."

version=$(sed -n 's/^ *MARKETING_VERSION: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p' $apple/project.yml | head -1)
[[ -n $version ]] || fail "No MARKETING_VERSION in apple/project.yml."
dmg=$build/Switchboard-$version-arm64.dmg

mkdir -p $build $cache

# 1. Node.js runtime ---------------------------------------------------------------------------
step "Node.js $NODE_VERSION"
tarball=node-v$NODE_VERSION-darwin-arm64.tar.gz
sums=$cache/SHASUMS256-v$NODE_VERSION.txt
if [[ ! -s $sums ]]; then
  curl --fail --silent --show-error --location -o $sums.part $NODE_DIST/SHASUMS256.txt
  mv $sums.part $sums
fi
expected=$(awk -v file=$tarball '$2 == file { print $1 }' $sums)
[[ -n $expected ]] || fail "$tarball is not listed in SHASUMS256.txt of v$NODE_VERSION."
verify_tarball() { [[ -s $cache/$tarball ]] && [[ $(shasum -a 256 $cache/$tarball | awk '{ print $1 }') == $expected ]] }
if ! verify_tarball; then
  print "Downloading $tarball"
  curl --fail --silent --show-error --location -o $cache/$tarball.part $NODE_DIST/$tarball
  mv $cache/$tarball.part $cache/$tarball
  verify_tarball || { rm -f $cache/$tarball; fail "$tarball does not match its SHA-256 in SHASUMS256.txt." }
fi
print "SHA-256 matches SHASUMS256.txt: $expected"
runtime=$build/runtime/node-v$NODE_VERSION-darwin-arm64
if [[ ! -x $runtime/bin/node ]]; then
  rm -rf $build/runtime
  mkdir -p $build/runtime
  tar -xzf $cache/$tarball -C $build/runtime
fi
node=$runtime/bin/node
npm=($node $runtime/lib/node_modules/npm/bin/npm-cli.js)
[[ $($node --version) == v$NODE_VERSION ]] || fail "The unpacked node does not report v$NODE_VERSION."

# 2. Stage the host ----------------------------------------------------------------------------
step "Staging the host in apple/build/stage/Host"
[[ -d $repo/node_modules ]] || (cd $repo && pnpm install --frozen-lockfile)
rm -rf $stage
mkdir -p $host/app/web

print "Building the web app"
(cd $repo && pnpm --filter @switchboard/web build)
[[ -f $repo/web/dist/index.html ]] || fail "web/dist/index.html is missing after the web build."
ditto $repo/web/dist $host/app/web/dist
cp $repo/roles.json $repo/projects.example.json $host/app/

print "Bundling the host code"
$node $scripts/bundle-host.mjs $repo $host/app

print "Installing the runtime packages with npm $(${npm[@]} --version) on node $NODE_VERSION"
$node $scripts/host-deps.mjs $repo/pnpm-lock.yaml $host/app/package.json
(
  cd $host/app
  PATH=$runtime/bin:$PATH ${npm[@]} install --omit=dev --no-package-lock --no-bin-links --ignore-scripts \
    --no-audit --no-fund --no-update-notifier --cache $cache/npm --loglevel=error
)
# better-sqlite3 ships Node-API prebuilds for every platform. Keep only this Mac's, and drop the
# SQLite and C++ sources it would only need to compile itself.
for prebuild in $host/app/node_modules/better-sqlite3/prebuilds/*.node(N); do
  [[ ${prebuild:t} == darwin-arm64.node ]] || rm -f $prebuild
done
rm -rf $host/app/node_modules/better-sqlite3/{deps,src,binding.gyp}
claude_package=$host/app/node_modules/@anthropic-ai/claude-agent-sdk-darwin-arm64
[[ -x $claude_package/claude ]] || fail "npm did not install @anthropic-ai/claude-agent-sdk-darwin-arm64."
links=$(find $host/app -type l | head -5)
[[ -z $links ]] || fail "The staged host contains symlinks:\n$links"

print "Writing Host/start, Host/node and Host/claude"
cp $node $host/node
chmod 755 $host/node
ln -s app/node_modules/@anthropic-ai/claude-agent-sdk-darwin-arm64/claude $host/claude
cat > $host/start <<'START'
#!/bin/zsh
# Starts the Switchboard host that ships inside Switchboard.app.
#
# Switchboard runs this with SWITCHBOARD_HOME set to the folder for settings and data, and with that
# folder as the working directory. Run by hand it falls back to the same folder the app uses.
# exec hands the process to node, so a signal to this process or its group reaches the host.
set -eu
host_dir=${0:A:h}
: ${SWITCHBOARD_HOME:=$HOME/Library/Application Support/Switchboard}
export SWITCHBOARD_HOME
[[ -d $SWITCHBOARD_HOME ]] || mkdir -p -m 700 "$SWITCHBOARD_HOME"
cd "$SWITCHBOARD_HOME"
# The bundled node and claude come last, so tools the agents run keep finding the user's own first.
export PATH=${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}:$host_dir
export NODE_ENV=production
exec "$host_dir/node" "$host_dir/app/host/dist/index.mjs" "$@"
START
chmod 755 $host/start

print "Checking the staged runtime"
(cd $host/app && $host/node -e "const Database = require('better-sqlite3'); const db = new Database(':memory:'); db.prepare('select 1').get(); db.close()") \
  || fail "better-sqlite3 does not load with the bundled node."
(cd $host/app && $host/node --input-type=module -e "await import('@anthropic-ai/claude-agent-sdk')") \
  || fail "The Agent SDK does not load with the bundled node."
print "better-sqlite3 and the Agent SDK load; claude $($host/claude --version)"

# 3. The Mac app -------------------------------------------------------------------------------
step "Building Switchboard.app (Release, arm64)"
(cd $apple && $xcodegen generate --quiet)
# Strip the executable as an archive would. Unstripped, its debug map names every source file by its
# absolute path on the build machine, home folder included. The dSYM stays in apple/build/release.
xcodebuild -project $apple/Switchboard.xcodeproj -scheme "Switchboard macOS" -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath $build/release ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  DEPLOYMENT_POSTPROCESSING=YES STRIP_INSTALLED_PRODUCT=YES build -quiet
built=$build/release/Build/Products/Release/Switchboard.app
[[ -d $built ]] || fail "xcodebuild did not produce $built."
rm -rf $build/dist
mkdir -p $build/dist
ditto $built $app_out
ditto $host $app_out/Contents/Resources/Host
xattr -cr $app_out

step "Signing inside out"
signer() { codesign -dvv $1 2>&1 | sed -n 's/^Authority=Developer ID Application: //p' }
# A valid Developer ID signature (node from nodejs.org, claude from Anthropic) is notarized and needs
# no hardened-runtime entitlements from us. Node's own entitlements allow loading the ad hoc addon.
is_vendor_signed() { codesign --verify --strict $1 2>/dev/null && [[ -n $(signer $1) ]] }
machos=()
while IFS= read -r -d '' file; do
  [[ $(file -b --mime-type $file) == application/x-mach-binary ]] && machos+=($file)
done < <(find $app_out/Contents/Resources/Host -type f -print0)
for file in $machos; do
  name=${file#$app_out/}
  if [[ $adhoc_all == false ]] && is_vendor_signed $file; then
    print "keep   $name ($(signer $file))"
  else
    codesign --force --sign - --timestamp=none $file
    print "ad hoc $name"
  fi
done
for nested in $app_out/Contents/Frameworks/*(N) $app_out/Contents/PlugIns/*(N); do
  codesign --force --sign - --timestamp=none --preserve-metadata=entitlements,requirements,flags,runtime $nested
done
codesign --force --sign - --timestamp=none --preserve-metadata=entitlements,requirements,flags,runtime $app_out
codesign --verify --deep --strict --verbose=2 $app_out

# 4. Disk image --------------------------------------------------------------------------------
step "Disk image"
rm -f $dmg
background=$apple/Packaging/dmg-background.tiff
[[ -f $background ]] || fail "apple/Packaging/dmg-background.tiff is missing. Run node apple/Packaging/render-background.mjs."
dmg_tool=dmgbuild
if command -v uvx >/dev/null || [[ -x $HOME/.local/bin/uvx ]]; then
  uvx=$(command -v uvx || print $HOME/.local/bin/uvx)
  if ! $uvx --quiet --from "dmgbuild==$DMGBUILD_VERSION" dmgbuild -s $apple/Packaging/dmg-settings.py \
      -D app=$app_out -D background=$background Switchboard $dmg; then
    print -u2 "dmgbuild failed, falling back to hdiutil with a plain layout."
    dmg_tool=hdiutil
  fi
else
  print -u2 "uvx is not installed, falling back to hdiutil with a plain layout."
  dmg_tool=hdiutil
fi
if [[ $dmg_tool == hdiutil ]]; then
  rm -rf $build/dmg-root
  mkdir -p $build/dmg-root
  ditto $app_out $build/dmg-root/Switchboard.app
  ln -s /Applications $build/dmg-root/Applications
  rm -f $dmg
  hdiutil create -volname Switchboard -srcfolder $build/dmg-root -format ULFO -ov $dmg -quiet
  rm -rf $build/dmg-root
fi
hdiutil verify -quiet $dmg

step "Checking the disk image"
mount_point=$(mktemp -d $build/mount.XXXXXX)
hdiutil attach -nobrowse -readonly -noautoopen -mountpoint $mount_point $dmg -quiet
detach() { hdiutil detach $mount_point -quiet 2>/dev/null || hdiutil detach $mount_point -force -quiet; rmdir $mount_point 2>/dev/null || true }
trap detach EXIT
[[ -d $mount_point/Switchboard.app && $(readlink $mount_point/Applications) == /Applications ]] \
  || fail "The disk image lacks Switchboard.app or the Applications link."
codesign --verify --deep --strict $mount_point/Switchboard.app || fail "The app in the disk image does not pass codesign --verify --strict."
print "Switchboard.app and the Applications link are there, and the signature verifies."
detach
trap - EXIT

app_size=$(du -sh $app_out | awk '{ print $1 }')
dmg_size=$(du -h $dmg | awk '{ print $1 }')
step "Done ($dmg_tool)"
print "App:  $app_out ($app_size)"
print "DMG:  $dmg ($dmg_size)"
