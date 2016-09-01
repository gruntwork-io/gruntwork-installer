# Packer File Copy

This module is intended to be used in a [Packer template](https://www.packer.io/) to move all files that template
copies into `/tmp/packer-files/XXX/YYY` into `/XXX/YYY`. For example, if you used the `file` provisioner to upload a
file to `/tmp/packer-files/foo/bar`, it will be moved to `/foo/bar`.

Why not just upload these files directly with Packer? Because:

1. If the destination folder doesn't exist, the `file` provisioner won't create it. Instead, you just get an error.
1. The `file` provisioner may not have permissions to write to certain folders (e.g. `/opt/my-app`) and it can't use
   `sudo`.

As a result, using the `file` provisioner is often a multi-step process where you first copy the files to a temporary
folder, then run scripts to create the real destination folder, move your files there, and update permissions. This
packer-file-copy module automates all these steps.

For an example of this module in action, see [examples/packer-file-copy](../../examples/packer-file-copy/).

IMPORTANT: The packer file provisioner should look like the following:

```json
{
    "type": "file",
    "source": "{{template_dir}}/files",
    "destination": "/tmp/packer-files"
}
```

Note how both the source and destination have no trailing slash. Adding a trailing slash will mean Packer will upload
files differently than intended.