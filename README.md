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

## Secrets

To edit the secret files, go into the `.dotfiles` folder and decrypt the file with
```bash
sops secrets/secret.yaml
```

Generating Secrets

```bash
#Generate new key at ~/.config/sops/age/keys.txt
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt

# generate new key at ~/.config/sops/age/keys.txt from private ssh key at ~/.ssh/private
nix run nixpkgs#ssh-to-age -- -private-key -i ~/.ssh/private > ~/.config/sops/age/keys.txt
```
