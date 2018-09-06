#!/usr/bin/env bash

set -u
set -x

assert()
{
  E_PARAM_ERR=98
  E_ASSERT_FAILED=99

  if [ -z "$2" ]
  then
    exit $E_PARAM_ERR
  fi

  lineno=$2

  if [ ! $1 ]
  then
    echo "Assertion failed:  \"$1\""
    echo "File \"$0\", line $lineno"
    exit $E_ASSERT_FAILED
  fi
}

# **START**

export GOPATH=$HOME
export PATH=$GOPATH/bin:$PATH
echo "machine github.com login $GITHUB_USERNAME password $GITHUB_PAT" >> $HOME/.netrc
echo "" >> $HOME/.netrc
echo "machine api.github.com login $GITHUB_USERNAME password $GITHUB_PAT" >> $HOME/.netrc
git config --global user.email "$GITHUB_USERNAME@example.com"
git config --global user.name "$GITHUB_USERNAME"
git config --global advice.detachedHead false
git config --global push.default current

# tidy up if we already have the repo
now=$(date +'%Y%m%d%H%M%S_%N')
githubcli repo renameIfExists go-modules-by-example-submodules go-modules-by-example-submodules_$now
assert "$? -eq 0" $LINENO
githubcli repo create go-modules-by-example-submodules
assert "$? -eq 0" $LINENO

# block: setup
mkdir go-modules-by-example-submodules
cd go-modules-by-example-submodules
git init -q
assert "$? -eq 0" $LINENO
git remote add origin https://github.com/$GITHUB_USERNAME/go-modules-by-example-submodules
assert "$? -eq 0" $LINENO

# block: define repo root module
go mod init github.com/$GITHUB_USERNAME/go-modules-by-example-submodules
git add go.mod
assert "$? -eq 0" $LINENO
git commit -q -am 'Initial commit'
assert "$? -eq 0" $LINENO
git push -q
assert "$? -eq 0" $LINENO

# block: create package b
mkdir b
cd b
cat <<EOD > b.go
package b

const Name = "Gopher"
EOD
go mod init github.com/$GITHUB_USERNAME/go-modules-by-example-submodules/b
go test
assert "$? -eq 0" $LINENO

# block: commit and tag b
cd ..
git add b
assert "$? -eq 0" $LINENO
git commit -q -am 'Add package b'
assert "$? -eq 0" $LINENO
git push -q
assert "$? -eq 0" $LINENO
git tag b/v0.1.1
assert "$? -eq 0" $LINENO
git push -q origin b/v0.1.1
assert "$? -eq 0" $LINENO

# block: create package a
mkdir a
cd a
cat <<EOD > .gitignore
/a
EOD
cat <<EOD > a.go
package main

import (
	"github.com/$GITHUB_USERNAME/go-modules-by-example-submodules/b"
	"fmt"
)

const Name = b.Name

func main() {
	fmt.Println(Name)
}
EOD
go mod init github.com/$GITHUB_USERNAME/go-modules-by-example-submodules/a

# block: run package a
go build
assert "$? -eq 0" $LINENO
./a
cat go.mod

# block: commit and tag a
cd ..
git add a
assert "$? -eq 0" $LINENO
git commit -q -am 'Add package a'
assert "$? -eq 0" $LINENO
git push -q
assert "$? -eq 0" $LINENO
git tag a/v1.0.0
assert "$? -eq 0" $LINENO
git push -q origin a/v1.0.0
assert "$? -eq 0" $LINENO

# block: version details
go version