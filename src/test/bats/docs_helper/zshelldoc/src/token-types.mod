# vim:ft=zsh

typeset -gA TOKEN_TYPES

TOKEN_TYPES=(

  # Precommand

  'builtin'     1
  'command'     1
  'exec'        1
  'nocorrect'   1
  'noglob'      1
  'pkexec'      1 # immune to #121 because it's usually not passed --option flags

  # Control flow
  # Tokens that at "command position" are followed by a command position.
  # All of these are reserved words.

  $'\x7b'   2 # block
  $'\x28'   2 # subshell
  '()'      2 # anonymous function
  'while'   2
  'until'   2
  'if'      2
  'then'    2
  'elif'    2
  'else'    2
  'do'      2
  'time'    2
  'coproc'  2
  '!'       2 # reserved word; unrelated to $histchars[1]

  # Command separators

  '|'   3
  '||'  3
  ';'   3
  '&'   3
  '&&'  3
  '|&'  3
  '&!'  3
  '&|'  3

  # ### 'case' syntax, but followed by a pattern, not by a command
  # ';;' ';&' ';|'
)
