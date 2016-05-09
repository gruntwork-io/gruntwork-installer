# Gruntwork Installer

[Gruntwork Script Modules](https://github.com/gruntwork-io/script-modules) is a private repo that contains scripts and
applications developed by [Gruntwork](http://www.gruntwork.io) for common infrastructure tasks such as setting up
continuous integration, monitoring, log aggregation, and SSH access. This repo provides a script called
`gruntwork-install` that makes it as easy to install a Script Module as using apt-get, brew, or yum.

For example, in your Packer and Docker templates, you can use `gruntwork-install` to install the [vault-ssh-helper
module](https://github.com/gruntwork-io/script-modules/tree/master/modules/vault-ssh-helper) as follows:

```bash
gruntwork-install --module-name 'vault-ssh-helper' --tag '0.0.3'
```

## Installing gruntwork-install

```bash
curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version 0.0.6
```

Notice the `--version` parameter at the end where you specify which version of `gruntwork-install` to install. See the
[releases](https://github.com/gruntwork-io/gruntwork-installer/releases) page for all available versions.

For paranoid security folks, see [is it safe to pipe URLs into bash?](#is-it-safe-to-pipe-urls-into-bash) below.

## Using gruntwork-install

#### Authentication

Since the [Script Modules](https://github.com/gruntwork-io/script-modules) repo is private, you must set your
[GitHub access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) as the
environment variable `GITHUB_OAUTH_TOKEN` so `gruntwork-install` can use it to access the repo:

```bash
export GITHUB_OAUTH_TOKEN="(your secret token)"
```

#### Options

Once that environment variable is set, you can run `gruntwork-install` with the following options:

Option           | Required | Description
---------------- | -------- | ------------
`--module-name`  | Yes      | The name of the Script Module to install. Can be any folder within the `modules` directory of the [Script Modules Repo](https://github.com/gruntwork-io/script-modules).
`--tag`          | Yes      | The version of the Script Module to install. Follows the syntax described at [Tag Constraint Expressions](https://github.com/gruntwork-io/fetch#tag-constraint-expressions).
`--module-param` | No       | A key-value pair of the format `key=value` you wish to pass to the module as a parameter. May be used multiple times. See the documentation for each module to find out what parameters it accepts.
`--help`         | No       | Show the help text and exit.

#### Examples

Install the [cloudwatch-log-aggregation
module](https://github.com/gruntwork-io/script-modules/tree/master/modules/cloudwatch-log-aggregation) version `0.0.3`:

```bash
gruntwork-install --module-name 'cloudwatch-log-aggregation' --tag '0.0.3'
```

Install the [vault-ssh-helper
module](https://github.com/gruntwork-io/script-modules/tree/master/modules/vault-ssh-helper), passing two custom
parameters to it:

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
    "inline": "curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version 0.0.6"
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

## How Gruntwork modules work

`gruntwork-install` is a fairly simple script that does the following:

1. Uses [fetch](https://github.com/gruntwork-io/fetch) to download the version of the module requested from
   [script-modules](https://github.com/gruntwork-io/script-modules).
1. Runs the `install.sh` script inside that module.

Future versions of `gruntwork-install` may do more (e.g. verify checksums, manage dependencies), but for now, that's
all there is to it.

That means that to add a new module to script-modules, all you have to do is include an `install.sh` script and it'll
automatically be installable!

## Is it safe to pipe URLs into bash?

Are you worried that our install instructions tell you to pipe a URL into bash? Although this approach has seen some
[backlash](https://news.ycombinator.com/item?id=6650987), we believe that the convenience of a one-line install
outweighs the minimal security risks. Below is a brief discussion of the most commonly discussed risks and what you can
do about them.

#### Risk #1: You don't know what the script is doing, so you shouldn't blindly execute it.

This is true of *all* installers. For example, have you ever inspected the install code before running `apt-get install`
or `brew install` or double cliking a `.dmg` or `.exe` file? If anything, a shell script is the most transparent
installer out there, as it's one of the few that allows you to inspect the code (feel free to do so, as this script is
open source!). The reality is that you either trust the developer or you don't. And eventually, you automate the
install process anyway, at which point manual inspection isn't a possibility anyway.

#### Risk #2: The download URL could be hijacked for malicious code.

This is unlikely, as it is an https URL, and your download program (e.g. `curl`) should be verifying SSL certs. That
said, Certificate Authorities have been hacked in the past, and perhaps the Gruntwork GitHub account could be hacked
in the future, so if that is a major concern for you, feel free to copy the bootstrap code into your own codebase and
execute it from there. Alternatively, in the future we will publish checksums of all of our releases, so you could
optionally verify the checksum before executing the script.

#### Risk #3: The script may not download fully and executing it could cause errors.

We wrote our [bootstrap-gruntwork-installer.sh](bootstrap-gruntwork-installer.sh) as a series of bash functions that
are only executed by the very last line of the script. Therefore, if the script doesn't fully download, the worst
that'll happen when you execute it is a harmless syntax error.

## TODO

1. Add support for a `--version` flag to `bootstrap-gruntwork-installer.sh` and `gruntwork-install`.
1. Configure a CI build to automatically set the `--version` flag for each release.
1. Add automated tests for this repo.
