To update the system please navigate to the .dotfiles directory and run:

```bash
nix flake update
```

To apply all changes from the system configuration:

```bash
sudo nixos-rebuild switch --flake .
```

and to apply home-manager

```bash
home-manager switch --flake .#nameofhomeconfiguration
```

## How to Install


```bash
git clone < ... > .dotfiles
```

Then run the above commands to rebuild the nix system.
NB: You must stage & commit any changes within the git repo before you rebuild the system. 

