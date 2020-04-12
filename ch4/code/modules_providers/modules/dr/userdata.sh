#!/bin/bash

set -xe

sudo amazon-linux-extras install nginx1.12
systemctl start nginx