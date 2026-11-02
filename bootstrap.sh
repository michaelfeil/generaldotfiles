#! /bin/bash
pushd $(dirname $0)
# This should match the one in aliases
DOTDIR="$HOME/.me"
rm -rf $DOTDIR
mkdir $DOTDIR
cp -rf * $DOTDIR

pushd $DOTDIR
> ~/.my_bashrc
for f in $(ls ./into_bashrc); do
  echo "source $DOTDIR/into_bashrc/$f" >> ~/.my_bashrc
done

grep -qxF "source ~/.my_bashrc" ~/.bashrc || echo "source ~/.my_bashrc" >> ~/.bashrc
popd

ln -f -s $DOTDIR/vimrc ~/.vimrc 
ln -f -s $DOTDIR/gitconfig ~/.gitconfig
ln -f -s $DOTDIR/tmux.conf ~/.tmux.conf
ln -f -s $DOTDIR/tmux-completion.bash ~/.tmux-completion.bash

mkdir -p ~/.codex
ln -f -s $DOTDIR/codex/config.toml ~/.codex/config.toml
ln -f -s $DOTDIR/codex/AGENTS.md ~/.codex/AGENTS.md

mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
ln -f -s "$DOTDIR/opencode/opencode.json" "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
popd
