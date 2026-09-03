#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
control="$repo_dir/scripts/omaglowctl"
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

pass_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
  printf 'not ok %d - %s\n' "$((pass_count + 1))" "$1" >&2
  exit 1
}

assert_contains() {
  local text=$1 expected=$2 label=$3
  [[ "$text" == *"$expected"* ]] || fail "$label (missing: $expected)"
  pass "$label"
}

output=$(OMAGLOW_CONFIG="$repo_dir/config/default.conf" "$control" check)
assert_contains "$output" "configuration is valid" "default configuration validates"

output=$(OMAGLOW_CONFIG="$repo_dir/config/default.conf" "$control" print)
assert_contains "$output" 'active_border = { colors = { "rgba(00d9ffe6)"' "opacity becomes border alpha"
assert_contains "$output" 'glow = { enabled = true, range = 8, render_power = 3, color = { colors = { "rgba(00d9ffa1)"' "intensity and opacity become glow alpha"
assert_contains "$output" 'leaf = "borderangle", enabled = true, speed = 45.00' "seconds become Hyprland deciseconds"
assert_contains "$output" 'leaf = "glowangle", enabled = true, speed = 45.00' "glow angle uses the same cycle"

if command -v lua >/dev/null 2>&1; then
  lua_code=${output#eval }
  lua_code=${lua_code//; eval /; }
  lua -e "hl = { config = function() end, animation = function() end }; $lua_code"
  pass "generated runtime configuration is valid Lua"
fi

printf 'speed=0.1\n' > "$test_dir/invalid.conf"
if OMAGLOW_CONFIG="$test_dir/invalid.conf" "$control" check >"$test_dir/out" 2>"$test_dir/err"; then
  fail "invalid speed is rejected"
fi
assert_contains "$(<"$test_dir/err")" "speed must be between" "invalid speed is rejected"

mkdir -p "$test_dir/bin" "$test_dir/runtime"
cat > "$test_dir/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MOCK_HYPRCTL_LOG:?}"
EOF
chmod +x "$test_dir/bin/hyprctl"

MOCK_HYPRCTL_LOG="$test_dir/hyprctl.log" \
PATH="$test_dir/bin:$PATH" \
XDG_RUNTIME_DIR="$test_dir/runtime" \
HYPRLAND_INSTANCE_SIGNATURE=test \
OMAGLOW_CONFIG="$repo_dir/config/default.conf" \
  "$control" apply >/dev/null
assert_contains "$(<"$test_dir/hyprctl.log")" "--batch eval hl.config({ general = { border_size = 2" "apply sends one Hyprland batch"

MOCK_HYPRCTL_LOG="$test_dir/hyprctl.log" \
PATH="$test_dir/bin:$PATH" \
XDG_RUNTIME_DIR="$test_dir/runtime" \
HYPRLAND_INSTANCE_SIGNATURE=test \
OMAGLOW_CONFIG="$repo_dir/config/default.conf" \
  "$control" reset >/dev/null
assert_contains "$(<"$test_dir/hyprctl.log")" "reload" "reset reloads the user's Hyprland configuration"

printf '1..%d\n' "$pass_count"
