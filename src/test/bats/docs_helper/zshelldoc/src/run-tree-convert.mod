# vim:ft=zsh

# A module, i.e. it provides multiple functions, not a single one.
# Public functions have `zsd' prefix.

# Converts tree (STDIN input) with possible
# special characters to ASCII-only
convert_tree()
{
    local IFSBKP="$IFS"
    IFS=""
    while read -r line; do
        line="${line//├──/|--}"
        line="${line//└──/\`--}"
        line="${line//│/|}"
        line="${line//_-_//}"
        echo "$line"
    done
    IFS="$IFSBKP"
}

# Searches for supported tree command,
# invokes to-ASCII conversion
zsd-run-tree-convert() {
    if type tree 2>/dev/null 1>&2; then
        tree -n --charset="utf-8" -- "$1" 2>&1 | convert_tree
    else
        {
            print "$fg[red]No \`tree' program, it is required$reset_color"
            print "Download from: http://mama.indstate.edu/users/ice/tree/"
            print "It is also available probably in all distributions and Homebrew, as package \`tree'"
            exit 1
        } >&2
    fi
}
