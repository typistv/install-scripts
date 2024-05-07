#!/bin/bash

git_email="typistchain@gmail.com"

ssh-keygen -t ed25519 -C "$git_email"

cat /root/.ssh/id_ed25519.pub
