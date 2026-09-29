#!/usr/bin/env bash
# quality-gate SETUP: installs the gate CLIs on the machine PATH (never as project dependencies)
# and writes the thin repo configs, the Quality Run scripts and lefthook.yml.
set -euo pipefail

LEFTHOOK_VERSION="2.1.14"
GITLEAKS_VERSION="8.30.1"
JQ_VERSION="1.8.2"
SEMGREP_VERSION="1.178.0"
JSCPD_VERSION="5.3.3"
# Go
STATICCHECK_VERSION="v0.8.1"   # 2026.2.1
X_TOOLS_VERSION="v0.50.0"      # deadcode
GOCYCLO_VERSION="v0.6.0"
GOCOGNIT_VERSION="v1.2.1"
GOSEC_VERSION="v2.29.0"
# Python
RUFF_VERSION="0.16.9"
MYPY_VERSION="2.3.1"
VULTURE_VERSION="2.16"
RADON_VERSION="6.0.1"
COMPLEXIPY_VERSION="8.0.1"
BANDIT_VERSION="1.9.4"
# JS/TS
BIOME_VERSION="2.5.14"
OXLINT_VERSION="1.86.0"
SONARJS_VERSION="4.2.2"      # eslint-plugin-sonarjs, loaded by Oxlint as a JS plugin (cognitive complexity)
KNIP_VERSION="6.38.0"
# PHP
PHP_CS_FIXER_VERSION="3.95.27"
PHPSTAN_VERSION="2.2.16"
PHPSTAN_EXTENSION_INSTALLER_VERSION="1.4.3"
COGNITIVE_COMPLEXITY_VERSION="1.2.0"
PHAN_VERSION="6.0.7"          # PHP >= 8.1; falls back to Phan 5 on PHP 8.0
PHPMD_VERSION="2.15.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "${SCRIPT_DIR}/../templates" && pwd)"
BIN_DIR="${QUALITY_GATE_BIN_DIR:-${HOME}/.local/bin}"
TOOLS_DIR="${QUALITY_GATE_TOOLS_DIR:-${HOME}/.local/share/quality-gate}"

FORCE=0
GIT_HOOKS=0
PLAN=0
ROOT="$(pwd)"
FAILED=()

usage() {
  cat >&2 <<'EOF'
usage: setup.sh [--plan] [--force] [--git-hooks] [--dir PATH]
  --plan       print what would be installed and written; change nothing
  --force      overwrite existing gate configs and scripts
  --git-hooks  run `lefthook install` (pre-commit + pre-push in this repo)
  --dir PATH   target repository (default: current directory)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan) PLAN=1; shift ;;
    --force) FORCE=1; shift ;;
    --git-hooks) GIT_HOOKS=1; shift ;;
    --dir) ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

cd "$ROOT"
export PATH="${BIN_DIR}:${PATH}"

have() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------------------ stack detection

list_src() {
  find . \( -path ./.git -o -path ./node_modules -o -path ./vendor -o -path ./.venv -o -path ./venv \
    -o -path ./.quality -o -path ./graphify-out \) -prune -o -type f \( "$@" \) -print -quit
}

has_python() { [[ -f pyproject.toml || -f uv.lock ]] || [[ -n "$(list_src -name '*.py')" ]]; }
has_go()     { [[ -f go.mod ]] || [[ -n "$(list_src -name '*.go')" ]]; }
has_js()     { [[ -f package.json ]] || [[ -n "$(list_src -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx')" ]]; }
has_php()    { [[ -f composer.json ]] || [[ -n "$(list_src -name '*.php')" ]]; }

GO=0; PY=0; JS=0; PHP=0
has_go && GO=1
has_python && PY=1
has_js && JS=1
has_php && PHP=1

# ------------------------------------------------------------------ helpers

os_name() {
  case "$(uname -s)" in
    Linux) echo linux ;;
    Darwin) echo darwin ;;
    *) echo unsupported ;;
  esac
}

arch_name() {
  case "$(uname -m)" in
    x86_64|amd64) echo x64 ;;
    arm64|aarch64) echo arm64 ;;
    *) echo unsupported ;;
  esac
}

fail() {
  echo "error: $*" >&2
  FAILED+=("$*")
}

download() {
  local p_url="$1" p_dest="$2"
  curl -fsSL --retry 2 "$p_url" -o "$p_dest"
}

# Planned or real install of one CLI: install_cli <bin> <description> <function>
install_cli() {
  local p_bin="$1" p_desc="$2" p_fn="$3"
  if have "$p_bin"; then
    echo "  = ${p_bin} (already on PATH)"
    return 0
  fi
  if [[ $PLAN -eq 1 ]]; then
    echo "  + ${p_bin}: ${p_desc}"
    return 0
  fi
  echo "installing ${p_bin} (${p_desc})"
  if ! "$p_fn"; then
    fail "failed to install ${p_bin}"
  elif ! "$p_bin" --version >/dev/null 2>&1; then
    fail "${p_bin} installed but does not run: $("$p_bin" --version 2>&1 | tail -n 3 | tr '\n' ' ')"
  fi
}

# ------------------------------------------------------------------ installers

install_lefthook() {
  local p_os p_arch p_tmp
  p_os="$(os_name)"; p_arch="$(arch_name)"
  if have mise && mise use -g "lefthook@${LEFTHOOK_VERSION}"; then return 0; fi
  [[ "$p_os" == unsupported || "$p_arch" == unsupported ]] && return 1
  [[ "$p_os" == linux ]] && p_os=Linux || p_os=MacOS
  [[ "$p_arch" == x64 ]] && p_arch=x86_64
  p_tmp="$(mktemp)"
  download "https://github.com/evilmartians/lefthook/releases/download/v${LEFTHOOK_VERSION}/lefthook_${LEFTHOOK_VERSION}_${p_os}_${p_arch}.gz" "$p_tmp" \
    && gunzip -c "$p_tmp" > "${BIN_DIR}/lefthook" && chmod +x "${BIN_DIR}/lefthook"
  local p_rc=$?
  rm -f "$p_tmp"
  return "$p_rc"
}

install_gitleaks() {
  local p_os p_arch p_tmp p_dir
  p_os="$(os_name)"; p_arch="$(arch_name)"
  if have mise && mise use -g "gitleaks@${GITLEAKS_VERSION}"; then return 0; fi
  [[ "$p_os" == unsupported || "$p_arch" == unsupported ]] && return 1
  p_tmp="$(mktemp)"; p_dir="$(mktemp -d)"
  download "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_${p_os}_${p_arch}.tar.gz" "$p_tmp" \
    && tar -xzf "$p_tmp" -C "$p_dir" && install -m 0755 "${p_dir}/gitleaks" "${BIN_DIR}/gitleaks"
  local p_rc=$?
  rm -rf "$p_tmp" "$p_dir"
  return $p_rc
}

install_jq() {
  local p_os p_arch
  p_os="$(os_name)"; p_arch="$(arch_name)"
  [[ "$p_os" == unsupported || "$p_arch" == unsupported ]] && return 1
  [[ "$p_os" == darwin ]] && p_os=macos
  [[ "$p_arch" == x64 ]] && p_arch=amd64
  download "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${p_os}-${p_arch}" "${BIN_DIR}/jq" \
    && chmod +x "${BIN_DIR}/jq"
}

install_biome() {
  local p_os p_arch
  p_os="$(os_name)"; p_arch="$(arch_name)"
  [[ "$p_os" == unsupported || "$p_arch" == unsupported ]] && return 1
  download "https://github.com/biomejs/biome/releases/download/%40biomejs%2Fbiome%40${BIOME_VERSION}/biome-${p_os}-${p_arch}" "${BIN_DIR}/biome" \
    && chmod +x "${BIN_DIR}/biome"
}

uv_tool() {
  local p_spec="$1"
  have uv || { echo "uv is required (https://docs.astral.sh/uv/)" >&2; return 1; }
  UV_TOOL_BIN_DIR="$BIN_DIR" uv tool install --quiet --force "$p_spec"
}

go_tool() {
  local p_pkg="$1"
  have go || { echo "go runtime not found" >&2; return 1; }
  GOBIN="$BIN_DIR" go install "$p_pkg"
}

npm_tool() {
  local p_pkg="$1"
  have npm || { echo "node/npm runtime not found" >&2; return 1; }
  npm install --global --silent --no-fund --no-audit "$p_pkg"
}

# Oxlint + eslint-plugin-sonarjs live in one isolated npm project under TOOLS_DIR; the `oxlint` on PATH
# is a wrapper that sets NODE_PATH so `.oxlintrc.json` resolves the `eslint-plugin-sonarjs` JS plugin.
install_oxlint() {
  have npm || { echo "node/npm runtime not found" >&2; return 1; }
  local p_dir="${TOOLS_DIR}/js/oxlint"
  mkdir -p "$p_dir"
  [[ -f "${p_dir}/package.json" ]] || echo '{"private": true}' > "${p_dir}/package.json"
  npm install --prefix "$p_dir" --silent --no-fund --no-audit \
    "oxlint@${OXLINT_VERSION}" "eslint-plugin-sonarjs@${SONARJS_VERSION}" || return 1
  cat > "${BIN_DIR}/oxlint" <<EOF
#!/usr/bin/env bash
# Generated by quality-gate SETUP: Oxlint with eslint-plugin-sonarjs resolvable as a JS plugin.
export NODE_PATH="${p_dir}/node_modules\${NODE_PATH:+:\$NODE_PATH}"
exec "${p_dir}/node_modules/.bin/oxlint" "\$@"
EOF
  chmod +x "${BIN_DIR}/oxlint"
}

# Each PHP tool lives in its own composer project under TOOLS_DIR (no dependency clashes between tools).
composer_tool() {
  local p_name="$1" p_bin="$2"
  shift 2
  have composer || { echo "composer not found" >&2; return 1; }
  local p_dir="${TOOLS_DIR}/php/${p_name}"
  mkdir -p "$p_dir"
  [[ -f "${p_dir}/composer.json" ]] || echo '{}' > "${p_dir}/composer.json"
  composer --working-dir="$p_dir" config --no-interaction allow-plugins.phpstan/extension-installer true || return 1
  composer --working-dir="$p_dir" require --no-interaction --quiet "$@" || return 1
  ln -sf "${p_dir}/vendor/bin/${p_bin}" "${BIN_DIR}/${p_bin}"
}

i_semgrep()      { uv_tool "semgrep==${SEMGREP_VERSION}"; }
i_jscpd()        { npm_tool "jscpd@${JSCPD_VERSION}"; }
i_staticcheck()  { go_tool "honnef.co/go/tools/cmd/staticcheck@${STATICCHECK_VERSION}"; }
i_deadcode()     { go_tool "golang.org/x/tools/cmd/deadcode@${X_TOOLS_VERSION}"; }
i_gocyclo()      { go_tool "github.com/fzipp/gocyclo/cmd/gocyclo@${GOCYCLO_VERSION}"; }
i_gocognit()     { go_tool "github.com/uudashr/gocognit/cmd/gocognit@${GOCOGNIT_VERSION}"; }
i_gosec()        { go_tool "github.com/securego/gosec/v2/cmd/gosec@${GOSEC_VERSION}"; }
i_ruff()         { uv_tool "ruff==${RUFF_VERSION}"; }
i_mypy()         { uv_tool "mypy==${MYPY_VERSION}"; }
i_vulture()      { uv_tool "vulture==${VULTURE_VERSION}"; }
i_radon()        { uv_tool "radon==${RADON_VERSION}"; }
i_complexipy()   { uv_tool "complexipy==${COMPLEXIPY_VERSION}"; }
i_bandit()       { uv_tool "bandit[sarif]==${BANDIT_VERSION}"; }
i_knip()         { npm_tool "knip@${KNIP_VERSION}"; }
i_php_cs_fixer() { composer_tool php-cs-fixer php-cs-fixer "friendsofphp/php-cs-fixer:${PHP_CS_FIXER_VERSION}"; }
i_phpstan() {
  composer_tool phpstan phpstan "phpstan/phpstan:${PHPSTAN_VERSION}" \
    "phpstan/extension-installer:${PHPSTAN_EXTENSION_INSTALLER_VERSION}" \
    "tomasvotruba/cognitive-complexity:${COGNITIVE_COMPLEXITY_VERSION}"
}
# Phan 6 needs PHP >= 8.1; Phan 5 covers PHP 8.0. Without ext-ast, run.sh uses the polyfill parser.
i_phan() {
  composer_tool phan phan "phan/phan:${PHAN_VERSION}" \
    || { echo "phan ${PHAN_VERSION} rejects this PHP; trying ^5" >&2
         composer_tool phan phan "phan/phan:^5"; }
}
i_phpmd()        { composer_tool phpmd phpmd "phpmd/phpmd:${PHPMD_VERSION}"; }

# ------------------------------------------------------------------ repo files

baseline_value() {
  local p_key="$1" p_default="$2"
  if [[ -f quality-baseline.json ]] && have jq; then
    jq -r --arg d "$p_default" ".${p_key} // \$d" quality-baseline.json
  else
    echo "$p_default"
  fi
}

php_dirs() {
  local p_dir p_found=0
  for p_dir in src app lib; do
    [[ -d "$p_dir" ]] && { echo "$p_dir"; p_found=1; }
  done
  [[ $p_found -eq 1 ]] || echo "."
}

# write_file <template> <dest> [already-configured-reason]
write_file() {
  local p_src="$1" p_dest="$2" p_skip="${3:-}"
  if [[ -n "$p_skip" ]]; then
    echo "  = ${p_dest} (${p_skip})"
    return 0
  fi
  if [[ -e "$p_dest" && $FORCE -eq 0 ]]; then
    echo "  = ${p_dest} (exists; --force to overwrite)"
    return 0
  fi
  if [[ $PLAN -eq 1 ]]; then
    echo "  + ${p_dest}"
    return 0
  fi
  mkdir -p "$(dirname "$p_dest")"
  local p_cog p_cyc p_paths_yaml p_paths_xml p_bootstrap
  p_cog="$(baseline_value cognitive_max 15)"
  p_cyc="$(baseline_value cyclomatic_max 10)"
  p_paths_yaml="$(php_dirs | sed 's/^/    - /')"
  p_paths_xml="$(php_dirs | sed 's|^\(.*\)$|        <directory name="\1"/>|')"
  p_bootstrap=""
  [[ -f composer.json ]] && p_bootstrap="  bootstrapFiles:
    - vendor/autoload.php"
  P_PATHS_YAML="$p_paths_yaml" P_PATHS_XML="$p_paths_xml" P_BOOTSTRAP="$p_bootstrap" \
  P_COG="$p_cog" P_CYC="$p_cyc" P_CYC_LEVEL="$((p_cyc + 1))" \
    awk '{
      gsub(/@COGNITIVE_MAX@/, ENVIRON["P_COG"]);
      gsub(/@CYCLOMATIC_MAX@/, ENVIRON["P_CYC"]);
      gsub(/@CYCLOMATIC_REPORT_LEVEL@/, ENVIRON["P_CYC_LEVEL"]);
      if ($0 == "@PHP_PATHS_YAML@") { print ENVIRON["P_PATHS_YAML"]; next }
      if ($0 == "@PHP_PATHS_XML@") { print ENVIRON["P_PATHS_XML"]; next }
      if ($0 == "@PHP_BOOTSTRAP@") { if (ENVIRON["P_BOOTSTRAP"] != "") print ENVIRON["P_BOOTSTRAP"]; next }
      print
    }' "$p_src" > "$p_dest"
  [[ "$p_dest" == *.sh ]] && chmod +x "$p_dest"
  echo "wrote ${p_dest}"
}

first_existing() {
  local p_file
  for p_file in "$@"; do [[ -e "$p_file" ]] && { echo "$p_file"; return 0; }; done
  return 1
}

pyproject_has() { [[ -f pyproject.toml ]] && grep -q "^\[$1\]" pyproject.toml; }

ensure_gitignore() {
  if [[ -f .gitignore ]] && grep -qxF '.quality/' .gitignore; then
    echo "  = .gitignore (.quality/ ignored)"
    return 0
  fi
  if [[ $PLAN -eq 1 ]]; then
    echo "  + .gitignore: .quality/"
    return 0
  fi
  printf '\n# quality-gate reports\n.quality/\n' >> .gitignore
  echo "wrote .gitignore (.quality/)"
}

# ------------------------------------------------------------------ run

mkdir -p "$BIN_DIR"
[[ $PLAN -eq 1 ]] && echo "quality-gate SETUP plan for ${ROOT} (nothing will change)"
echo "stack: go=${GO} python=${PY} js/ts=${JS} php=${PHP}"
echo "CLIs -> ${BIN_DIR}:"

install_cli lefthook "Lefthook ${LEFTHOOK_VERSION} (release binary)" install_lefthook
install_cli gitleaks "Gitleaks ${GITLEAKS_VERSION} (release binary)" install_gitleaks
install_cli jq "jq ${JQ_VERSION} (release binary)" install_jq
install_cli semgrep "Semgrep ${SEMGREP_VERSION} (uv tool)" i_semgrep
install_cli jscpd "jscpd ${JSCPD_VERSION} (npm -g)" i_jscpd

if [[ $GO -eq 1 ]]; then
  have gofmt || fail "gofmt not found: install the Go toolchain (runtimes are never installed by SETUP)"
  install_cli staticcheck "staticcheck ${STATICCHECK_VERSION} (go install)" i_staticcheck
  install_cli deadcode "deadcode x/tools ${X_TOOLS_VERSION} (go install)" i_deadcode
  install_cli gocyclo "gocyclo ${GOCYCLO_VERSION} (go install)" i_gocyclo
  install_cli gocognit "gocognit ${GOCOGNIT_VERSION} (go install)" i_gocognit
  install_cli gosec "gosec ${GOSEC_VERSION} (go install)" i_gosec
fi
if [[ $PY -eq 1 ]]; then
  install_cli ruff "Ruff ${RUFF_VERSION} (uv tool)" i_ruff
  install_cli mypy "mypy ${MYPY_VERSION} (uv tool)" i_mypy
  install_cli vulture "Vulture ${VULTURE_VERSION} (uv tool)" i_vulture
  install_cli radon "Radon ${RADON_VERSION} (uv tool)" i_radon
  install_cli complexipy "complexipy ${COMPLEXIPY_VERSION} (uv tool)" i_complexipy
  install_cli bandit "Bandit ${BANDIT_VERSION} + SARIF (uv tool)" i_bandit
fi
if [[ $JS -eq 1 ]]; then
  install_cli biome "Biome ${BIOME_VERSION} (release binary)" install_biome
  install_cli knip "Knip ${KNIP_VERSION} (npm -g)" i_knip
  install_cli oxlint "Oxlint ${OXLINT_VERSION} + eslint-plugin-sonarjs ${SONARJS_VERSION} (isolated npm project)" install_oxlint
fi
if [[ $PHP -eq 1 ]]; then
  have php || fail "php not found: install PHP (runtimes are never installed by SETUP)"
  install_cli php-cs-fixer "PHP-CS-Fixer ${PHP_CS_FIXER_VERSION} (isolated composer project)" i_php_cs_fixer
  install_cli phpstan "PHPStan ${PHPSTAN_VERSION} + cognitive-complexity ${COGNITIVE_COMPLEXITY_VERSION} (isolated composer project)" i_phpstan
  install_cli phan "Phan ${PHAN_VERSION} (isolated composer project)" i_phan
  install_cli phpmd "PHPMD ${PHPMD_VERSION} (isolated composer project)" i_phpmd
fi

echo "repo files:"
write_file "${TEMPLATE_DIR}/quality-baseline.json" quality-baseline.json
write_file "${TEMPLATE_DIR}/scripts/quality/run.sh" scripts/quality/run.sh
write_file "${TEMPLATE_DIR}/scripts/quality/aggregate.sh" scripts/quality/aggregate.sh
write_file "${TEMPLATE_DIR}/lefthook.yml" lefthook.yml "$(first_existing lefthook.yaml .lefthook.yml .lefthook.yaml >/dev/null && echo 'another lefthook config exists; merge jobs by hand' || true)"
write_file "${TEMPLATE_DIR}/gitleaks.toml" .gitleaks.toml
write_file "${TEMPLATE_DIR}/jscpd.json" .jscpd.json
ensure_gitignore

if [[ $PY -eq 1 ]]; then
  write_file "${TEMPLATE_DIR}/ruff.toml" ruff.toml "$(pyproject_has tool.ruff && echo 'pyproject [tool.ruff]' || { first_existing .ruff.toml >/dev/null && echo '.ruff.toml exists'; } || true)"
  write_file "${TEMPLATE_DIR}/mypy.ini" mypy.ini "$(pyproject_has tool.mypy && echo 'pyproject [tool.mypy]' || { first_existing .mypy.ini setup.cfg >/dev/null && echo 'mypy config exists'; } || true)"
fi
if [[ $JS -eq 1 ]]; then
  write_file "${TEMPLATE_DIR}/biome.json" biome.json "$(first_existing biome.jsonc >/dev/null && echo 'biome.jsonc exists' || true)"
  write_file "${TEMPLATE_DIR}/oxlintrc.json" .oxlintrc.json "$(first_existing .oxlintrc.jsonc oxlint.config.ts >/dev/null && echo 'another oxlint config exists; merge the complexity rules by hand' || true)"
fi
if [[ $PHP -eq 1 ]]; then
  write_file "${TEMPLATE_DIR}/php-cs-fixer.dist.php" .php-cs-fixer.dist.php "$(first_existing .php-cs-fixer.php >/dev/null && echo '.php-cs-fixer.php exists; point run.sh at it' || true)"
  write_file "${TEMPLATE_DIR}/phpstan.neon" phpstan.neon "$(first_existing phpstan.neon.dist phpstan.dist.neon >/dev/null && echo 'phpstan dist config exists' || true)"
  write_file "${TEMPLATE_DIR}/phan-config.php" .phan/config.php
  write_file "${TEMPLATE_DIR}/phpmd.xml" phpmd.xml
fi

if [[ $GIT_HOOKS -eq 1 ]]; then
  if [[ $PLAN -eq 1 ]]; then
    echo "git hooks: + lefthook install (pre-commit, pre-push)"
  elif have lefthook; then
    lefthook install
  else
    fail "lefthook missing; git hooks not installed"
  fi
fi

case ":${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) echo "warning: add ${BIN_DIR} to PATH" ;;
esac

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "quality-gate SETUP finished with ${#FAILED[@]} error(s):" >&2
  printf '  - %s\n' "${FAILED[@]}" >&2
  exit 1
fi
[[ $PLAN -eq 1 ]] && { echo "plan only: re-run without --plan to apply"; exit 0; }
echo "quality-gate SETUP done in ${ROOT}"
