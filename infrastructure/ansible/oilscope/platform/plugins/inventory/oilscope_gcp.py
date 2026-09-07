# SPDX-License-Identifier: GPL-2.0-or-later
"""Discover OilScope instances in GCP and AWS from the project JSON."""

import json
import os
import tempfile

import yaml
from ansible.errors import AnsibleParserError
from ansible.plugins.inventory import BaseInventoryPlugin, Cacheable


DOCUMENTATION = r"""
name: oilscope_gcp
short_description: Discover OilScope VMs in GCP and AWS
version_added: "0.1.0"
description:
  - Reads the same project JSON as Terraform.
  - Uses C(default_cloud) and each VM's optional C(cloud) override.
  - Delegates discovery to the standard GCP and AWS inventory plugins.
extends_documentation_fragment:
  - inventory_cache
options:
  plugin:
    description: Token identifying this inventory plugin.
    type: str
    required: true
    choices: [oilscope.platform.oilscope_gcp]
  project_config_path:
    description: Path to the project JSON shared with Terraform.
    type: str
    default: ../../terraform/config/dev.json
    env:
      - name: OILSCOPE_PROJECT_CONFIG
requirements:
  - google.cloud
  - amazon.aws
  - google-auth
  - boto3
"""

EXAMPLES = r"""
plugin: oilscope.platform.oilscope_gcp
cache: false
"""

DELEGATES = {
    "gcp": "google.cloud.gcp_compute",
    "aws": "amazon.aws.aws_ec2",
}


class InventoryModule(BaseInventoryPlugin, Cacheable):
    NAME = "oilscope.platform.oilscope_gcp"

    def verify_file(self, path):
        return super().verify_file(path) and path.endswith(("oilscope.yml", "oilscope.yaml"))

    def parse(self, inventory, loader, path, cache=True):
        super().parse(inventory, loader, path, cache=cache)
        self._read_config_data(path)
        config = self._load_config(path)

        selected_clouds = {
            vm.get("cloud", config["default_cloud"])
            for vm in config["vms"].values()
        }
        builders = {
            "gcp": self._gcp_settings,
            "aws": self._aws_settings,
        }

        try:
            for cloud in sorted(selected_clouds):
                self._delegate(
                    inventory,
                    loader,
                    builders[cloud](config),
                    cloud,
                    cache,
                )
        except (KeyError, TypeError, ValueError) as error:
            raise AnsibleParserError(f"invalid multi-cloud project configuration: {error}") from error

    def _load_config(self, inventory_path):
        configured = os.path.expanduser(str(self.get_option("project_config_path")))
        config_path = configured if os.path.isabs(configured) else os.path.join(
            os.path.dirname(os.path.abspath(inventory_path)), configured
        )

        try:
            with open(os.path.normpath(config_path), encoding="utf-8") as handle:
                return json.load(handle)
        except (OSError, ValueError) as error:
            raise AnsibleParserError(f"could not read project configuration: {error}") from error

    @staticmethod
    def _location(config, cloud, kind):
        key = config["location"][kind]
        return config["clouds"][cloud][f"{kind}s"][key]

    @staticmethod
    def _bastion_port(config):
        return int(config["vms"]["bastion"]["ssh_port"])

    def _gcp_settings(self, config):
        cloud = "gcp"
        cloud_config = config["clouds"][cloud]
        bastion_port = self._bastion_port(config)
        is_bastion = "labels.role | default('') == 'bastion'"
        private_ip = "networkInterfaces[0].networkIP"
        public_ip = "networkInterfaces[0].accessConfigs[0].natIP"
        has_public_ip = "networkInterfaces[0].accessConfigs | default([])"

        return {
            "plugin": DELEGATES[cloud],
            "projects": [cloud_config["project_id"]],
            "zones": [self._location(config, cloud, "zone")],
            "filters": [
                f"labels.application = {config['name_prefix']}",
                f"labels.environment = {config['environment']}",
                "labels.cloud = gcp",
            ],
            "auth_kind": "application",
            "hostnames": ["name"],
            "vars_prefix": "gcp_",
            "keyed_groups": self._groups("labels"),
            "groups": {"workloads": "labels.role is defined and labels.role != 'bastion'"},
            "compose": {
                "internal_ip": private_ip,
                "public_ip": f"{public_ip} if {has_public_ip} else ''",
                "ansible_host": f"{public_ip} if {is_bastion} else {private_ip}",
                "ansible_port": f"{bastion_port} if {is_bastion} else 22",
                "bastion_ssh_port": str(bastion_port),
                "oilscope_role": "labels.role | default('')",
                "oilscope_cloud": "labels.cloud | default('gcp')",
            },
            "cache": bool(self.get_option("cache")),
        }

    def _aws_settings(self, config):
        cloud = "aws"
        bastion_port = self._bastion_port(config)
        is_bastion = "tags.role | default('') == 'bastion'"

        return {
            "plugin": DELEGATES[cloud],
            "regions": [self._location(config, cloud, "region")],
            "filters": {
                "instance-state-name": "running",
                "tag:application": config["name_prefix"],
                "tag:environment": config["environment"],
                "tag:cloud": cloud,
            },
            "hostnames": ["tag:Name"],
            "strict": False,
            "keyed_groups": self._groups("tags"),
            "groups": {"workloads": "tags.role is defined and tags.role != 'bastion'"},
            "compose": {
                "internal_ip": "private_ip_address",
                "public_ip": "public_ip_address | default('')",
                "ansible_host": f"public_ip_address if {is_bastion} else private_ip_address",
                "ansible_port": f"{bastion_port} if {is_bastion} else 22",
                "ansible_user": "'ubuntu'",
                "bastion_ssh_port": str(bastion_port),
                "oilscope_role": "tags.role | default('')",
                "oilscope_cloud": "tags.cloud | default('aws')",
            },
            "cache": bool(self.get_option("cache")),
        }

    @staticmethod
    def _groups(source):
        return [
            {"key": f"{source}.role", "prefix": "", "separator": ""},
            {"key": f"{source}.cloud", "prefix": "cloud", "separator": "_"},
        ]

    @staticmethod
    def _delegate(inventory, loader, settings, cloud, cache):
        from ansible.plugins.loader import inventory_loader

        suffix = ".gcp.yml" if cloud == "gcp" else ".aws_ec2.yml"
        descriptor, generated = tempfile.mkstemp(prefix="oilscope-", suffix=suffix)
        os.close(descriptor)

        try:
            with open(generated, "w", encoding="utf-8") as handle:
                yaml.safe_dump(settings, handle, default_flow_style=False)

            delegate = inventory_loader.get(DELEGATES[cloud])
            if delegate is None:
                raise AnsibleParserError(f"inventory plugin {DELEGATES[cloud]} is not installed")
            delegate.parse(inventory, loader, generated, cache=cache)
        finally:
            os.unlink(generated)
