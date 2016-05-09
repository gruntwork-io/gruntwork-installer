# Gruntwork Installer

[Gruntwork Script Modules](https://github.com/gruntwork-io/script-modules) is a private repo that contains scripts and
applications developed by [Gruntwork](http://www.gruntwork.io) for common infrastructure tasks such as setting up
continuous integration, monitoring, log aggregation, and SSH access. This repo contains provides a script called
`gruntwork-install` that makes it as easy to install the Gruntwork Script Modules as using apt-get, brew, or yum.

For example, in your Packer and Docker templates, you can use `gruntwork-install` as follows:

```bash
gruntwork-install --module-name 'vault-ssh-helper' --tag '0.0.3'
```

## Installing gruntwork-install

```bash
curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash -s --version=0.0.1
```

Notice the `--version` parameter at the end where you specify which version of `gruntwork-install` to install. See the
[releases](/releases) page for all available versions.

## Using gruntwork-install

#### Authentication

Since the [Script Modules](https://github.com/gruntwork-io/script-modules) repo is private, you must set your
[GitHub access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) as the
environment variable `GITHUB_OAUTH_TOKEN` so `gruntwork-install` can use it to access the repo:

```bash
export GITHUB_OAUTH_TOKEN="..."
```

#### Options

Once that environment variable is set, you can run `gruntwork-install` with the following options:

* `--module-name`: Required. The name of the Script Module to install. Can be any folder within the `modules` directory
  of the [Script Modules Repo](https://github.com/gruntwork-io/script-modules).
* `--tag`: Required. The version of the Script Module to install. Follows the syntax described at [Fetch Version
  Constraint Operators](https://github.com/gruntwork-io/fetch#version-constraint-operators).
* `--branch`: Optional. Download the latest commit from this branch. This is an alternative to `--tag` for development
  purposes.
* `--module-param`: Optional. A key-value pair of the format `key=value` you wish to pass to the module as a parameter.
  May be used multiple times. See the documentation for each module to find out what parameters it accepts.
* `--help`: Optional. Show the help text and exit.

#### Examples

Here is how you could use `gruntwork-install` to install the `vault-ssh-helper` module, version `0.0.3`:

```bash
gruntwork-install --module-name 'vault-ssh-helper' --tag '0.0.3'
```

And here is an example of using `--module-param` to pass two custom parameters to the `vault-ssh-helper` module:

```bash
gruntwork-install --module-name 'vault-ssh-helper' --tag '0.0.3' --module-param 'install-dir=/opt/vault-ssh-helper' --module-param 'owner=ubuntu'
```

And finally, to put all the pieces together, here is an example of a Packer template that installs `gruntwork-install`
and then uses it to install several modules:

```json
{
  "variables": {
    "github_auth_token": "{{env `GITHUB_OAUTH_TOKEN`}}"
  },
  "builders": [{
    "ami_name": "gruntwork-install-example-{{isotime | clean_ami_name}}",
    "instance_type": "t2.micro",
    "region": "us-east-1",
    "type": "amazon-ebs",
    "source_ami": "ami-fce3c696",
    "ssh_username": "ubuntu"
  }],
  "provisioners": [{
    "type": "shell",
    "inline": "curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash -s --version=0.0.1"
  },{
    "type": "shell",
    "inline": [
      "gruntwork-install --module-name 'vault-ssh-helper' --tag '~>0.0.4' --module-param 'install-dir=/opt/vault-ssh-helper' --module-param 'owner=ubuntu'",
      "gruntwork-install --module-name 'cloudwatch-log-aggregation' --tag '~>0.0.4'",
      "gruntwork-install --module-name 'build-helpers' --tag '~>0.0.4'"
    ],
    "environment_vars": [
      "GITHUB_OAUTH_TOKEN={{user `github_auth_token`}}"
    ]
  }]
}
```