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
