#!/bin/bash
# git ready [branch]
# git ready # current branch
ref=$1
if [[ -z $ref ]]; then
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    ref=$(echo "${ref#refs/heads/}")
fi

if [[ $ref =~ 'ready' ]] ; then
    echo "$ref is ready already."
    exit;
fi

ready=ready/$ref
echo "Moving branch $ref to $ready"
git branch -m $ref $ready

git remote | while read remote ; do
    echo "Pushing new branch $ready to remote"
    git push $remote $ready
    echo "Removing local branch $ref"
    git push $remote :$ref
done

echo "Updating remote"
git remote update --prune

echo "Gc-ing"
git gc --aggresive --prune=now

echo -e "$ref => $ready"
echo -e "\033[1;32mBranch $ref ready. \033[0m"
