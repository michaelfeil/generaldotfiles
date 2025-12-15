âexport NONINTERACTIVE=1 

apt-get update
apt-get install -y nano apache2-utils build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm \
              libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libpq-dev \
              protobuf-compiler libprotobuf-dev python3-dev curl file git procps musl-tools

# uv and cli tools
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -sSL https://install.python-poetry.org | python3 -
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup target add x86_64-unknown-linux-musl 
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> ~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

brew install derailed/k9s/k9s

git config --global user.name michaelfeil
git config --global user.email 63565275+michaelfeil@users.noreply.github.com
# pip 
pip install ruff uv --break-system-packages

curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz \
              && tar -xf vscode_cli.tar.gz \
              && cp code /usr/local/bin/ \
              && rm  vscode_cli.tar.gz 
# ~/.config/Code/User/globalStorage/ms-vscode.remote-server/server-token
code tunnel user login --provider github

tmux new-session -s vscode -c "$(pwd)" "bash tunnel_code.sh"
