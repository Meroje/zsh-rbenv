[[ -z "$RBENV_DIR" ]] && export RBENV_DIR="$HOME/.rbenv"

_zsh_rbenv_global_binaries() {

  # Look for global binaries
  local global_binary_paths="$(echo "$RBENV_DIR"/shims/*(N))"

  # If we have some, format them
  if [[ -n "$global_binary_paths" ]]; then
    echo "$RBENV_DIR"/shims/*(N) |
      xargs -n 1 basename |
      sort |
      uniq
  fi
}

_zsh_rbenv_load() {
  eval "$(rbenv init - --no-rehash zsh)"
}

_zsh_rbenv_lazy_load() {

  # Get all global node module binaries including node
  # (only if RBENV_NO_USE is off)
  local global_binaries
  if [[ "$RBENV_NO_USE" == true ]]; then
    global_binaries=()
  else
    global_binaries=($(_zsh_rbenv_global_binaries))
  fi

  # Add rbenv
  global_binaries+=('rbenv')

  # Remove any binaries that conflict with current aliases
  local cmds
  cmds=()
  for bin in $global_binaries; do
    [[ "$(which $bin 2> /dev/null)" = "$bin: aliased to "* ]] || cmds+=($bin)
  done

  # Create function for each command
  for cmd in $cmds; do

    # When called, unset all lazy loaders, load rbenv then run current command
    eval "$cmd(){
      unset -f $cmds > /dev/null 2>&1
      _zsh_rbenv_load
      $cmd \"\$@\"
    }"
  done
}

# Don't init anything if this is true (debug/testing only)
if [[ "$ZSH_RBENV_NO_LOAD" != true ]]; then

  # If rbenv is installed
  if (( $+commands[rbenv] )); then
    path=("$RBENV_DIR/bin" $path)
    # Load it
    [[ "$RBENV_LAZY_LOAD" == true ]] && _zsh_rbenv_lazy_load || _zsh_rbenv_load

    if [ -d "/usr/local/opt/rbenv" ]; then
        source "/usr/local/opt/rbenv/completions/rbenv.zsh"
    else
        source "$(brew --prefix rbenv)/completions/rbenv.zsh"
    fi
  fi

fi

# Make sure we always return good exit code
# We can't `return 0` because that breaks antigen
true
