
zsh_highlight__aliases=`builtin alias -Lm '[^+]*'`
builtin unalias -m '[^+]*'
0=${(%):-%N}
if true; then
  typeset -g ZSH_HIGHLIGHT_VERSION=$(<"${0:A:h}"/.version)
  typeset -g ZSH_HIGHLIGHT_REVISION=$(<"${0:A:h}"/.revision-hash)
  if [[ $ZSH_HIGHLIGHT_REVISION == \$Format:* ]]; then
    ZSH_HIGHLIGHT_REVISION=HEAD
  fi
fi
autoload -U is-at-least
if is-at-least 5.3.2; then
  zsh_highlight__pat_static_bug=false
else
  zsh_highlight__pat_static_bug=true
fi
typeset -ga ZSH_HIGHLIGHT_HIGHLIGHTERS
typeset -gA ZSH_HIGHLIGHT_STYLES
_zsh_highlight_bind_widgets || {
  print -r -- >&2 'zsh-syntax-highlighting: failed binding ZLE widgets, exiting.'
  return 1
}
_zsh_highlight_load_highlighters "${ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR:-${${0:A}:h}/highlighters}" || {
  print -r -- >&2 'zsh-syntax-highlighting: failed loading highlighters, exiting.'
  return 1
}
autoload -U add-zsh-hook
add-zsh-hook preexec _zsh_highlight_preexec_hook 2>/dev/null || {
    print -r -- >&2 'zsh-syntax-highlighting: failed loading add-zsh-hook.'
  }
zmodload zsh/parameter 2>/dev/null || true
[[ $#ZSH_HIGHLIGHT_HIGHLIGHTERS -eq 0 ]] && ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
eval "$zsh_highlight__aliases"
builtin unset zsh_highlight__aliases
true
