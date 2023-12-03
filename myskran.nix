{ config, inputs, system, pkgs, lib, shared, user, modulesPath, ... }:

{
  networking = with shared; {
    hostName = user.handle;
    usePredictableInterfaceNames = true;
    # has been renamed to `ipv4.addresses'.
    interfaces.enp5s0.ipv4.addresses = [{
      address = "192.168.13.100";
      prefixLength = 24;
    }];
    nameservers = dns;
    defaultGateway = "192.168.13.1";
    firewall.enable = false;
  };
}
