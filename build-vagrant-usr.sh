#!/usr/bin/env bash

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.37.2/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install --lts --no-progress
nvm alias default stable
npm install npm@latest yarn -g

# Clear history
cat /dev/null > ~/.bash_history && history -c
