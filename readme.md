To run the VM:

```
nix run .#
```

To terminate the VM, hit `C-a c` and type `quit`.

From another terminal, run Nomad jobs:

```
export NOMAD_ADDR=http://127.0.0.1:34646
nomad run jobs/helloworld.hcl
nomad run jobs/traefik.hcl
```
