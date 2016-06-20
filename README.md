# Gruntwork Installer

At [Gruntwork](http://www.gruntwork.io/), we've developed a number of scripts and binaries, most of them in private
repos, that perform common infrastructure tasks such as setting up continuous integration, monitoring, log aggregation,
and SSH access. This repo provides a script called `gruntwork-install` that makes it as easy to install Gruntwork
scripts and binaries as using apt-get, brew, or yum.

For example, in your Packer and Docker templates, you can use `gruntwork-install` to install the [ecs-scripts
module](https://github.com/gruntwork-io/module-ecs/tree/master/modules/ecs-scripts) as follows:

```
gruntwork-install --module-name 'ecs-scripts' --repo 'https://github.com/gruntwork-io/module-ecs' --tag '0.0.1'
```

## Installing gruntwork-install

```
curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version 0.0.11
```

Notice the `--version` parameter at the end where you specify which version of `gruntwork-install` to install. See the
[releases](https://github.com/gruntwork-io/gruntwork-installer/releases) page for all available versions.

For paranoid security folks, see [is it safe to pipe URLs into bash?](#is-it-safe-to-pipe-urls-into-bash) below.

## Using gruntwork-install

#### Authentication

To install scripts and binaries from private Gruntwork repos, you must create a [GitHub access
token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) and set it as the environment
variable `GITHUB_OAUTH_TOKEN` so `gruntwork-install` can use it to access the repo:

```
export GITHUB_OAUTH_TOKEN="(your secret token)"
```

#### Options

Once that environment variable is set, you can run `gruntwork-install` with the following options:

Option           | Required | Description
---------------- | -------- | ------------
`--repo`         | Yes      | The GitHub repo to install from.
`--tag`          | Yes      | The version of the `--repo` to install from. Follows the syntax described at [Tag Constraint Expressions](https://github.com/gruntwork-io/fetch#tag-constraint-expressions).
`--module-name`  | No       | The name of a module to install. Can be any folder within the `modules` directory of `--repo`. You must specify exactly one of `--module-name` or `--binary-name`.
`--binary-name`  | No       | The name of a binary to install. Can be any file uploaded as a release asset in `--repo`.  You must specify exactly one of `--module-name` or `--binary-name`.
`--module-param` | No       | A key-value pair of the format `key=value` you wish to pass to the module as a parameter. May be used multiple times. See the documentation for each module to find out what parameters it accepts.
`--help`         | No       | Show the help text and exit.

#### Examples

Install the [ecs-scripts
module](https://github.com/gruntwork-io/module-ecs/tree/master/modules/ecs-scripts) from the [module-ecs
repo](https://github.com/gruntwork-io/module-ecs), version `0.0.1`:

```
gruntwork-install --module-name 'ecs-scripts' --repo 'https://github.com/gruntwork-io/module-ecs' --tag '0.0.1'
```

Install the [vault-ssh-helper
module](https://github.com/gruntwork-io/script-modules/tree/master/modules/vault-ssh-helper) from the [script-modules
repo](https://github.com/gruntwork-io/script-modules), passing two custom parameters to it:

```
gruntwork-install --module-name 'vault-ssh-helper' --repo 'https://github.com/gruntwork-io/script-modules' --tag '0.0.3' --module-param 'install-dir=/opt/vault-ssh-helper' --module-param 'owner=ubuntu'
```

Install the `gruntkms` binary from the `v0.0.1` release of the [gruntkms
repo](https://github.com/gruntwork-io/gruntkms):

```
gruntwork-install --binary-name 'gruntkms' --repo 'https://github.com/gruntwork-io/gruntkms' --tag 'v0.0.1'
```

Note that the [v0.0.1 release of the gruntkms repo](https://github.com/gruntwork-io/gruntkms/releases/tag/v0.0.1) has
multiple binaries (`gruntkms_linux_amd64`, `gruntkms_darwin_386`, etc): `gruntwork-install` automatically picks the
right binary for your OS and copies it to `/usr/local/bin/gruntkms`.

Finally, to put all the pieces together, here is an example of a Packer template that installs `gruntwork-install`
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
    "inline": "curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version 0.0.11"
  },{
    "type": "shell",
    "inline": [
      "gruntwork-install --module-name 'ecs-scripts' --repo 'https://github.com/gruntwork-io/module-ecs' --tag '0.0.1'",
      "gruntwork-install --module-name 'vault-ssh-helper' --repo 'https://github.com/gruntwork-io/script-modules' --tag '0.0.3' --module-param 'install-dir=/opt/vault-ssh-helper' --module-param 'owner=ubuntu'",
      "gruntwork-install --binary-name 'gruntkms' --repo 'https://github.com/gruntwork-io/gruntkms' --tag 'v0.0.1'"
    ],
    "environment_vars": [
      "GITHUB_OAUTH_TOKEN={{user `github_auth_token`}}"
    ]
  }]
}
```

## How Gruntwork modules work

`gruntwork-install` does the following:

1. Uses [fetch](https://github.com/gruntwork-io/fetch) to download the specified version of the module or binary from
   the repo specified via the `--repo` option.
1. If you used the `--module-name` parameter, it downloads the module from the `modules` folder of `--repo` and runs
   the `install.sh` script of that module.
1. If you used the `--binary-name` parameter, it downloads the right binary for your OS, copies it to `/usr/local/bin`,
   and gives it execute permissions.

Future versions of `gruntwork-install` may do more (e.g. verify checksums, manage dependencies), but for now, that's
all there is to it.

That means that to create an installable module, all you have to do is put it in the `modules` folder and include an
`install.sh` script; to create an installable binary, you just publish it to a GitHub release with the name format
`<NAME>_<OS>_<ARCH>`.

## Running tests

The tests for this repo are defined in the `test` folder. They are designed to run in a Docker container so that you
do not repeatedly dirty up your local OS while testing. We've defined a `test/docker-compose.yml` file as a convenient
way to expose the environment variables we need for testing and to mount local directories as volumes for rapid
iteration.

To run the tests:

1. Set your [GitHub access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) as
   the environment variable `GITHUB_OAUTH_TOKEN`.
1. `./_ci/run-tests.sh`

## Is it safe to pipe URLs into bash?

Are you worried that our install instructions tell you to pipe a URL into bash? Although this approach has seen some
[backlash](https://news.ycombinator.com/item?id=6650987), we believe that the convenience of a one-line install
outweighs the minimal security risks. Below is a brief discussion of the most commonly discussed risks and what you can
do about them.

#### Risk #1: You don't know what the script is doing, so you shouldn't blindly execute it.

This is true of *all* installers. For example, have you ever inspected the install code before running `apt-get install`
or `brew install` or double clicking a `.dmg` or `.exe` file? If anything, a shell script is the most transparent
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
1. Add an `uninstall` command that uses an `uninstall.sh` script in each module.
1. Add support for modules declaring their dependencies. Alternatively, consider Nix again as a dependency manager.