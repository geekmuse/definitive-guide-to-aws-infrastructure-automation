#!/bin/bash

sudo apt install nodejs
sudo apt install npm
sudo apt install python3
sudo apt install python3-pip
echo "alias python=\"python3\"" >> ~/.bashrc
echo "alias pip=\"pip3\"" >> ~/.bashrc
source ~/.bashrc
sudo npm install -g aws-cdk
sudo pip install --user aws-cdk.core
sudo apt-get install python3-venv
