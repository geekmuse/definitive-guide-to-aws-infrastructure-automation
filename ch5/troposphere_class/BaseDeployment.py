#!/usr/bin/env python

from abc import ABC, abstractmethod
import boto3

class AbstractDeployment(ABC):

    def __init__(self, d):
        self.deployment_type = d
        super().__init__()
    

    def gen_template(self):
        return self.template.to_yaml()


    def dump_template(self, output_file=None):
        if output_file is None:
            output_file = f'{self.deployment_type}_template.yml'
        print(f'Generating template to {output_file}...')
        with open(f'{output_file}', 'w') as fp:
            fp.write(self.template.to_yaml())


    def build(self, client=None):
        if client is None:
            client = boto3.client('cloudformation')

        print(f'Building stack {self.deployment_type}-tropo...')
        client.create_stack(
            StackName=f'{self.deployment_type}-tropo',
            TemplateBody=self.gen_template(),
        )

