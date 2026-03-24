#!/usr/bin/env bash
# CVM - Claude Version Manager
# Per-terminal version switching for Claude Code
# Source this file in your .zshrc/.bashrc:  source ~/.claude-versions/cvm.sh

export CVM_DIR="$HOME/.claude-versions"

# ── Colors ──
_CVM_C_RESET="\033[0m"
_CVM_C_BOLD="\033[1m"
_CVM_C_DIM="\033[2m"
_CVM_C_GREEN="\033[32m"
_CVM_C_YELLOW="\033[33m"
_CVM_C_CYAN="\033[36m"
_CVM_C_RED="\033[31m"
_CVM_C_ORANGE="\033[38;5;215m"
_CVM_C_PEACH="\033[38;5;209m"

# ── Detect system Claude version on first source (cached) ──
_cvm_sys_cache="$CVM_DIR/.sys_version"
if [[ -z "$CVM_ACTIVE" ]]; then
  if [[ -f "$_cvm_sys_cache" ]]; then
    export CVM_SYS_VERSION=$(cat "$_cvm_sys_cache")
  else
    _v=$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if [[ -n "$_v" ]]; then
      echo "$_v" > "$_cvm_sys_cache"
      export CVM_SYS_VERSION="$_v"
    fi
    unset _v
  fi
  export CVM_VERSION="${CVM_SYS_VERSION:-unknown}"
fi

# ── Main entry ──
cvm() {
  local cmd="$1"
  shift 2>/dev/null

  case "$cmd" in
    install)     _cvm_install "$@" ;;
    uninstall)   _cvm_uninstall "$@" ;;
    activate)    _cvm_activate "$@" ;;
    deactivate)  _cvm_deactivate ;;
    list|ls)     _cvm_list ;;
    current)     _cvm_current ;;
    refresh)     _cvm_refresh_cache ;;
    *)           _cvm_help ;;
  esac
}

# ── Install ──
_cvm_install() {
  local version="$1"
  if [[ -z "$version" ]]; then
    echo -e "${_CVM_C_YELLOW}Usage:${_CVM_C_RESET} cvm install <version>"
    echo -e "e.g.:  cvm install 2.1.77 | cvm install latest"
    return 1
  fi

  if [[ "$version" == "latest" ]]; then
    echo -e "${_CVM_C_DIM}Fetching latest version...${_CVM_C_RESET}"
    version=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
    if [[ -z "$version" ]]; then
      echo -e "${_CVM_C_RED}✗ Failed to fetch latest version${_CVM_C_RESET}"
      return 1
    fi
    echo -e "Latest: ${_CVM_C_CYAN}${_CVM_C_BOLD}$version${_CVM_C_RESET}"
  fi

  local install_dir="$CVM_DIR/$version"

  if [[ -d "$install_dir/node_modules" ]]; then
    echo -e "${_CVM_C_GREEN}✓${_CVM_C_RESET} Version ${_CVM_C_CYAN}$version${_CVM_C_RESET} already installed"
    return 0
  fi

  echo -e "${_CVM_C_ORANGE}⟳${_CVM_C_RESET} Installing ${_CVM_C_BOLD}@anthropic-ai/claude-code@$version${_CVM_C_RESET} ..."
  mkdir -p "$install_dir"
  npm install --prefix "$install_dir" "@anthropic-ai/claude-code@$version" 2>&1

  if [[ $? -eq 0 && -x "$install_dir/node_modules/.bin/claude" ]]; then
    echo -e "${_CVM_C_GREEN}${_CVM_C_BOLD}✓ Installed: $version${_CVM_C_RESET}"
    echo -e "  Run ${_CVM_C_CYAN}cvm activate $version${_CVM_C_RESET} to use it in this terminal"
  else
    echo -e "${_CVM_C_RED}${_CVM_C_BOLD}✗ Installation failed${_CVM_C_RESET}"
    rm -rf "$install_dir"
    return 1
  fi
}

# ── Uninstall ──
_cvm_uninstall() {
  local version="$1"
  if [[ -z "$version" ]]; then
    echo -e "${_CVM_C_YELLOW}Usage:${_CVM_C_RESET} cvm uninstall <version>"
    return 1
  fi

  local install_dir="$CVM_DIR/$version"
  if [[ ! -d "$install_dir" ]]; then
    echo -e "${_CVM_C_RED}✗${_CVM_C_RESET} Version $version is not installed"
    return 1
  fi

  if [[ "$CVM_ACTIVE" == "$version" ]]; then
    echo -e "${_CVM_C_YELLOW}⚠${_CVM_C_RESET} Run ${_CVM_C_CYAN}cvm deactivate${_CVM_C_RESET} first"
    return 1
  fi

  rm -rf "$install_dir"
  echo -e "${_CVM_C_GREEN}✓${_CVM_C_RESET} Uninstalled ${_CVM_C_DIM}$version${_CVM_C_RESET}"
}

# ── Activate ──
_cvm_activate() {
  local version="$1"
  if [[ -z "$version" ]]; then
    echo -e "${_CVM_C_YELLOW}Usage:${_CVM_C_RESET} cvm activate <version>"
    _cvm_list
    return 1
  fi

  local bin_dir="$CVM_DIR/$version/node_modules/.bin"
  if [[ ! -x "$bin_dir/claude" ]]; then
    echo -e "${_CVM_C_RED}✗${_CVM_C_RESET} Version $version not installed. Run: ${_CVM_C_CYAN}cvm install $version${_CVM_C_RESET}"
    return 1
  fi

  if [[ -n "$CVM_ACTIVE" ]]; then
    _cvm_deactivate 2>/dev/null
  fi

  export CVM_OLD_PATH="$PATH"
  export CVM_ACTIVE="$version"
  export CVM_VERSION="$version"
  export PATH="$bin_dir:$PATH"

  echo -e "${_CVM_C_PEACH}✦${_CVM_C_RESET} ${_CVM_C_BOLD}claude@$version${_CVM_C_RESET} ${_CVM_C_GREEN}activated${_CVM_C_RESET} ${_CVM_C_DIM}— this terminal only${_CVM_C_RESET}"
}

# ── Deactivate ──
_cvm_deactivate() {
  if [[ -z "$CVM_ACTIVE" ]]; then
    echo -e "${_CVM_C_DIM}No active cvm environment${_CVM_C_RESET}"
    return 0
  fi

  local old_version="$CVM_ACTIVE"
  export PATH="$CVM_OLD_PATH"
  unset CVM_ACTIVE
  unset CVM_OLD_PATH
  export CVM_VERSION="${CVM_SYS_VERSION:-unknown}"

  echo -e "${_CVM_C_PEACH}✦${_CVM_C_RESET} ${_CVM_C_DIM}Deactivated claude@$old_version${_CVM_C_RESET} → system (${CVM_VERSION})"
}

# ── List ──
_cvm_list() {
  local current_active="$CVM_ACTIVE"
  local found=0

  echo -e "${_CVM_C_BOLD}${_CVM_C_PEACH}✦ Claude Code Versions${_CVM_C_RESET}"
  echo ""

  # system-installed
  local sys_claude=""
  if [[ -z "$CVM_ACTIVE" ]]; then
    sys_claude=$(command -v claude 2>/dev/null)
  else
    sys_claude=$(PATH="$CVM_OLD_PATH" command -v claude 2>/dev/null)
  fi
  if [[ -n "$sys_claude" ]]; then
    local sys_ver="${CVM_SYS_VERSION:-?}"
    if [[ -z "$CVM_ACTIVE" ]]; then
      echo -e "  ${_CVM_C_GREEN}▸${_CVM_C_RESET} ${_CVM_C_BOLD}${_CVM_C_GREEN}$sys_ver${_CVM_C_RESET}  ${_CVM_C_DIM}system · $sys_claude${_CVM_C_RESET}  ${_CVM_C_GREEN}● active${_CVM_C_RESET}"
    else
      echo -e "    ${_CVM_C_DIM}$sys_ver  system · $sys_claude${_CVM_C_RESET}"
    fi
    found=1
  fi

  # cvm-managed versions
  local dir
  for dir in "$CVM_DIR"/*/node_modules/.bin/claude; do
    [[ -x "$dir" ]] || continue
    found=1
    local ver="${dir%/node_modules/.bin/claude}"
    ver="${ver##*/}"
    if [[ "$ver" == "$current_active" ]]; then
      echo -e "  ${_CVM_C_GREEN}▸${_CVM_C_RESET} ${_CVM_C_BOLD}${_CVM_C_GREEN}$ver${_CVM_C_RESET}  ${_CVM_C_DIM}cvm${_CVM_C_RESET}  ${_CVM_C_GREEN}● active${_CVM_C_RESET}"
    else
      echo -e "    $ver  ${_CVM_C_DIM}cvm${_CVM_C_RESET}"
    fi
  done

  echo ""
  if [[ $found -eq 0 ]]; then
    echo -e "  ${_CVM_C_DIM}(empty) Run: cvm install <version>${_CVM_C_RESET}"
  fi
}

# ── Current ──
_cvm_current() {
  echo -e "${_CVM_C_PEACH}✦${_CVM_C_RESET} ${_CVM_C_BOLD}Claude Code${_CVM_C_RESET}"
  if [[ -n "$CVM_ACTIVE" ]]; then
    echo -e "  env:   ${_CVM_C_CYAN}cvm${_CVM_C_RESET} → ${_CVM_C_GREEN}${_CVM_C_BOLD}$CVM_ACTIVE${_CVM_C_RESET}"
  else
    echo -e "  env:   ${_CVM_C_CYAN}system${_CVM_C_RESET} → ${_CVM_C_GREEN}${_CVM_C_BOLD}${CVM_SYS_VERSION:-?}${_CVM_C_RESET}"
  fi
  echo -e "  path:  ${_CVM_C_DIM}$(command -v claude 2>/dev/null || echo 'not found')${_CVM_C_RESET}"
  echo -e "  ver:   $(claude --version 2>/dev/null || echo 'not found')"
}

# ── Refresh system version cache ──
_cvm_refresh_cache() {
  local _v
  _v=$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  if [[ -n "$_v" ]]; then
    echo "$_v" > "$CVM_DIR/.sys_version"
    export CVM_SYS_VERSION="$_v"
    if [[ -z "$CVM_ACTIVE" ]]; then
      export CVM_VERSION="$_v"
    fi
    echo -e "${_CVM_C_GREEN}✓${_CVM_C_RESET} System version cache updated: ${_CVM_C_BOLD}$_v${_CVM_C_RESET}"
  else
    echo -e "${_CVM_C_RED}✗${_CVM_C_RESET} No system claude found"
  fi
}

# ── Help ──
_cvm_help() {
  echo ""
  echo -e "${_CVM_C_BOLD}${_CVM_C_PEACH}  ✦  CVM${_CVM_C_RESET} ${_CVM_C_DIM}— Claude Version Manager${_CVM_C_RESET}"
  echo ""
  echo -e "  ${_CVM_C_BOLD}Commands${_CVM_C_RESET}                      ${_CVM_C_DIM}Description${_CVM_C_RESET}"
  echo -e "  ${_CVM_C_DIM}─────────────────────────────────────────────${_CVM_C_RESET}"
  echo -e "  ${_CVM_C_CYAN}cvm install${_CVM_C_RESET} <version>       Install a version ${_CVM_C_DIM}(e.g. 2.1.77, latest)${_CVM_C_RESET}"
  echo -e "  ${_CVM_C_CYAN}cvm uninstall${_CVM_C_RESET} <version>     Remove a version"
  echo -e "  ${_CVM_C_GREEN}cvm activate${_CVM_C_RESET} <version>     ${_CVM_C_BOLD}Activate in current terminal${_CVM_C_RESET}"
  echo -e "  ${_CVM_C_YELLOW}cvm deactivate${_CVM_C_RESET}             Deactivate, back to system"
  echo -e "  ${_CVM_C_CYAN}cvm list${_CVM_C_RESET}                    List installed versions"
  echo -e "  ${_CVM_C_CYAN}cvm current${_CVM_C_RESET}                 Show active version details"
  echo -e "  ${_CVM_C_CYAN}cvm refresh${_CVM_C_RESET}                 Refresh system version cache"
  echo ""
  echo -e "  ${_CVM_C_DIM}Examples:${_CVM_C_RESET}"
  echo -e "  ${_CVM_C_DIM}\$${_CVM_C_RESET} cvm install 2.1.77 && cvm install latest"
  echo -e "  ${_CVM_C_DIM}\$${_CVM_C_RESET} cvm activate 2.1.77    ${_CVM_C_DIM}# Terminal A: stable${_CVM_C_RESET}"
  echo -e "  ${_CVM_C_DIM}\$${_CVM_C_RESET} cvm activate latest     ${_CVM_C_DIM}# Terminal B: bleeding edge${_CVM_C_RESET}"
  echo ""
}
