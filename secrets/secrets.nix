let
  raddservernix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJF8T/GvNM1wsImQqBulPf3hFmmtZsFGUJ7EVMjrUHo";
  callumleach = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAH8wW5JADjP/VptatTNMZs6VJ2GPIEkmu6ZEIeaOpsQ";
  users = [ callumleach ];
in
{
  "cloudflare_dns_api.age".publicKeys = users ++ [ raddservernix ];
  "homepage.age".publicKeys = users ++ [ raddservernix ];
}
