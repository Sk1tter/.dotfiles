# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export EDITOR='nvim'

# JAVA_HOME variable
export JAVA_HOME=$(/usr/libexec/java_home)

# colored ls and cd <tab> completion
export CLICOLOR=1

export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# nord LS_COLORS ?
#
fpath+=~/.zfunc
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
autoload -Uz compinit
compinit

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias cd.='cd ..'
alias cd..='cd ..'
alias l='ls -alF'
alias ll='ls -l'
alias vi='\vim'
alias vim='nvim'
eval "$(hub alias -s)"

# user brew installed ctags
alias ctags="`brew --prefix`/bin/ctags"

# source control dotfiles directory with alias dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# pretty git graph
alias gitv='git log --graph --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

# ctags for python
alias python_ctags="ctags -R --fields=+l --languages=python --python-kinds=-iv -f ./tags . $(python3 -c "import os, sys; print(' '.join('{}'.format(d) for d in sys.path if os.path.isdir(d)))")"

source ~/emrtest.sh

awsc() {
    open https://ap-northeast-2.console.aws.amazon.com/console/home\?region=ap-northeast-2#
}

google() {
  open "https://www.google.com/search?q="$1
}

github() {(
    set -e
    git remote -v | grep push
    remote=${1:-origin}
    echo "Using remote $remote"

    URL=$(git config remote.$remote.url | sed "s/git@\(.*\):\(.*\).git/https:\/\/\1\/\2/")
    echo "Opening $URL..."
    open $URL
)}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# ###
# fzf functions
# ###

bindkey "ç" fzf-cd-widget

Rg() {
  local selected=$(
    rg --column --line-number --no-heading --color=always --smart-case "$1" |
      fzf --ansi --preview "~/.vim/plugged/fzf.vim/bin/preview.sh {}"
  )
  [ -n "$selected" ] && $EDITOR "+${${selected#*:}%%:*}" "${selected%%:*}"
}

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
  fzf --height 50% "$@" --border
}

# export FZF_DEFAULT_OPTS='
#     --color fg:#D8DEE9,bg:#2E3440,hl:#A3BE8C,fg+:#D8DEE9,bg+:#434C5E,hl+:#A3BE8C
#     --color pointer:#BF616A,info:#4C566A,spinner:#4C566A,header:#4C566A,prompt:#81A1C1,marker:#EBCB8B
# '

export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard' --border"

if command -v fd > /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git'
    export FZF_ALT_C_COMMAND='fd --type directory --hidden --follow --exclude .git --exclude Library'
    export FZF_CTRL_T_COMMAND='fd --type file --type directory --hidden --follow --exclude .git'
fi

command -v bat  > /dev/null && export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}'"
command -v tree > /dev/null && export FZF_ALT_C_OPTS="--preview 'tree --charset=unicode -C -N {} | head -200'"

# fd - cd to selected directory
#fd() {
#  local dir
#  dir=$(find ${1:-.} -path '*/\.*' -prune \
#                  -o -type d -print 2> /dev/null | fzf +m) &&
#  cd "$dir"
#}

# fh - search in your command history and execute selected command
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

# fzf cd
function cd() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -p | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" |
            fzf --reverse --preview "tree --charset=unicode -C -N -L 2 {} | head -200"'
                __cd_nxt="$(echo {})";
                __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
                echo $__cd_path;
                echo;
                ls -p -FG "${__cd_path}";
        ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &> /dev/null
    done
}

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() (
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-nvim} "${files[@]}"
)

# fco - checkout git branch/tag
fco() {
  is_in_git_repo || return
  local tags branches target
  tags=$(git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
  branches=$(
    git branch --all | grep -v HEAD             |
    sed "s/.* //"    | sed "s#remotes/[^/]*/##" |
    sort -u          | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
  target=$(
    (echo "$tags"; echo "$branches") | sed '/^$/d' |
    fzf-down --no-hscroll --reverse --ansi +m -d "\t" -n 2 -q "$*")|| return
  git checkout $(echo "$target" | awk '{print $2}')
}

gf() {
  is_in_git_repo || return
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
  cut -c4- | sed 's/.* -> //'
}

gb() {
  is_in_git_repo || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

gt() {
  is_in_git_repo || return
  git tag --sort -version:refname |
  fzf-down --multi --preview-window right:70% \
    --preview 'git show --color=always {} | head -'$LINES
}

gh() {
  is_in_git_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES |
  grep -o "[a-f0-9]\{7,\}"
}

gr() {
  is_in_git_repo || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
  cut -d$'\t' -f1
}

gs() {
  is_in_git_repo || return
  git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
  cut -d: -f1
}

# Extra
gp() {
  ps -ef | fzf-down --header-lines 1 --info inline --layout reverse --multi |
    awk '{print $2}'
}

join-lines() {
  local item
  while read item; do
    echo -n "${(q)item} "
  done
}

bind-git-helper() {
  local c
  for c in $@; do
    eval "fzf-g$c-widget() { local result=\$(g$c | join-lines); zle reset-prompt; LBUFFER+=\$result }"
    eval "zle -N fzf-g$c-widget"
    eval "bindkey '^g^$c' fzf-g$c-widget"
  done
}
bind-git-helper f b t r h
unset -f bind-git-helper

pods() {
  local selected tokens
  selected=$(
    kubectl get pods --all-namespaces |
      fzf --info=inline --layout=reverse --header-lines=1 --border \
          --prompt "$(kubectl config current-context | sed 's/-context$//')> " \
          --header $'Press CTRL-O to open log in editor\n\n' \
          --bind ctrl-/:toggle-preview \
          --bind 'ctrl-o:execute:${EDITOR:-vim} <(kubectl logs --namespace {1} {2}) > /dev/tty' \
          --preview-window up:follow \
          --preview 'kubectl logs --follow --tail=100000 --namespace {1} {2}' "$@"
  )
  read -r tokens <<< "$selected"
  [ ${#tokens} -gt 1 ] &&
    kubectl exec -it --namespace "${tokens[0]}" "${tokens[1]}" -- bash
}

clusters() {
  local selected=$(
    kubectl config get-contexts -o=name |
      fzf-down -m --ansi --nth 2 \
        --header "Current context : $(kubectl config current-context | sed 's/-context$//')> "
  )
  [ -n "$selected" ] && kubectl config use-context "$selected"
}

export PATH="$HOME/.poetry/bin:$PATH"
eval "$(pyenv init -)"

# ###
# plugins
# ###

# colored man pages
source ~/.zsh/zsh-colored-man-pages/zsh-colored-man-pages.plugin.zsh
# zsh autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
# syntax highlighting : must be at end of zshrc
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

