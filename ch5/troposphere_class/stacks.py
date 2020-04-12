#!/usr/bin/env

from Deployments import DevDeployment, ProdDeployment

dev = DevDeployment()
print(dev.gen_template())

prod = ProdDeployment()
prod.build()