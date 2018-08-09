# Zshelldoc - Doxygen For Shell Scripts

Parses `Zsh` and `Bash` scripts, outputs `Asciidoc` document with:
- list of functions, including autoload functions,
- call trees of functions and script body,
- comments for functions,
- features used for each function and for script body (features like: `eval`, `read`, `vared`, `shopt`, etc.),
- distinct marks for hooks registered with `add-zsh-hook` (Zsh),
- list of exported variables,
- list of used exported variables, together with the variable's origin (i.e. possibly other script).

Call trees support cross-file invocations, i.e. when a script calls functiion defined in other file.

Written in `Zshell` language.

![image](https://raw.githubusercontent.com/zdharma/zshelldoc/images/env_feat_demo.png)

# Usage

```
zsd [-h/--help] [-v/--verbose] [-q/--quiet] [-n/--noansi] [--cignore <pattern>] {file1} [file2] ...
The files will be processed and their documentation will be generated
in subdirectory `zsdoc' (with meta-data in subdirectory `data').

Options:
-h/--help      Usage information
-v/--verbose   More verbose operation-status output
-q/--quiet     No status messages
-n/--noansi    No colors in terminal output
--cignore      Specify which comment lines should be ignored
-f/--fpath     Paths separated by : pointing to directories with functions
--synopsis     Text to be used in SYNOPSIS section. Line break "... +\n", paragraph "...\n\n"
--scomm        Strip comment char "#" from function comments
--bash         Output slightly tailored to Bash specifics (instead of Zsh specifics)

Example --cignore options:
--cignore '\#*FUNCTION:*{{{*'                 - ignore comments like: # FUNCTION: usage {{{
--cignore '(\#*FUNCTION:*{{{*|\#*FUN:*{{{*)'  - also ignore comments like: # FUN: usage {{{

File is parsed for synopsis block, which can be e.g.:
# synopsis {{{my synopsis, can be multi-line}}}
Change the default brace delimeters with --blocka, --blockb. Block body should be AsciiDoc.

```

# Installation

Clone and issue `make && make install`. Default install path-prefix is `/usr/local`, you
can change it by setting `PREFIX` variable in `make` invocation:

```SystemVerilog
% make install PREFIX=~/opt/local
install -c -d ~/opt/local/share/zshelldoc
install -c -d ~/opt/local/share/doc/zshelldoc
cp build/zsd build/zsd-transform build/zsd-detect build/zsd-to-adoc ~/opt/local/bin
cp README.md NEWS LICENSE ~/opt/local/share/doc/zshelldoc
cp zsd.config ~/opt/local/share/zshelldoc

% tree ~/opt
/Users/sgniazdowski/opt
└── local
    ├── bin
    │   ├── zsd
    │   ├── zsd-detect
    │   ├── zsd-to-adoc
    │   └── zsd-transform
    └── share
        ├── doc
        │   └── zshelldoc
        │       ├── LICENSE
        │       ├── NEWS
        │       └── README.md
        └── zshelldoc
            └── zsd.config
```

Other available `make` variables are: `INSTALL` (to customize install command),
`BIN_DIR`, `SHARE_DIR`, `DOC_DIR`.

# Examples

`Zshelldoc` highly motivates to document code, my other project `Zplugin` gained from this.
Also, `Zplugin` documentation demonstrates rich cross-file invocations.
[Check out Zplugin's code documentation](https://github.com/zdharma/zplugin/tree/master/zsdoc).

For other, in-place examples see:
[example 1](https://github.com/zdharma/zshelldoc/blob/master/examples/zsh-syntax-highlighting.zsh.adoc),
[example 2](https://github.com/zdharma/zshelldoc/blob/master/examples/zsh-autosuggestions.zsh.adoc)
(also in **PDF**:
[example 1](https://raw.githubusercontent.com/zdharma/zshelldoc/master/examples/zsh-syntax-highlighting.zsh.pdf),
[example 2](https://raw.githubusercontent.com/zdharma/zshelldoc/master/examples/zsh-autosuggestions.zsh.pdf)).

# Few Rules

Few rules helping to use `Zshelldoc` in your project:

 1. Write function comments before function. Empty lines between comment and function are allowed.
 1. If you use special comments, e.g. `vim` (or `emacs-origami`) **folds**, you can ignore these lines with `--cignore` (see [Usage](https://github.com/zdharma/zshelldoc#usage)).
 1. If it's possible to avoid `eval`, then do that – `Zshelldoc` will analyze more code.
 1. Currently, functions defined in functions are ignored, but this will change shortly.
 1. I've greatly optimized new `Zsh` version (`5.4.2`) for data processing – `Zshelldoc` parses long sources very fast starting from that `Zsh` version.
 1. If you have multiple `Zsh` versions installed, then (for example) set `zsh_control_bin="/usr/local/bin/zsh-5.4.2"` in `/usr/local/share/zshelldoc/zsd.config`.
 1. Be aware that to convert a group of scripts, you simply need `zsd file1.zsh file2.zsh ...` – cross-file function invocations will work automatically, and multiple `*.adoc` files will be created.
 1. Create `Makefile` with `doc` target, that does `rm -rf zsdoc/data; zsd -v file1.zsh ...`. Documentation will land in `zsdoc` directory.
 1. Directory `zsdoc/data` holds meta-data used to create `asciidoc` documents (`*.adoc` files). You can remove it or analyze it yourself.
 1. Obtain **PDFs** with [Asciidoctor](http://asciidoctor.org/) tool via: `asciidoctor -b pdf -r asciidoctor-pdf file1.zsh.adoc`. Install `Asciidoctor` with: `gem install asciidoctor-pdf --pre`. (Check out [Zplugin's Makefile](https://github.com/zdharma/zplugin/blob/master/zsdoc/Makefile).)
 1. HTML: `asciidoctor script.adoc`.
 1. Obtain manual pages with `Asciidoc` package via: `a2x -L --doctype manpage --format manpage file1.zsh.adoc` (`asciidoc` is a common package; its `a2x` command is little slow).
 1. Github supports `Asciidoc` documents and renders them automatically.
