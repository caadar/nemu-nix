{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.nemu;
in {
  options = {
    programs.nemu = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to add nEMU to the global environment and configure a
          setcap wrapper for it.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [ nemu ];

    security.wrappers = {

      nemu.source = "${pkgs.nemu}/bin/nemu";
      nemu.capabilities = "cap_net_admin+ep";

      qemu-system-x86_64.source = "${pkgs.qemu}/bin/qemu-system-x86_64";
      qemu-system-x86_64.capabilities = "cap_net_admin+ep";

      qemu-system-i386.source = "${pkgs.qemu}/bin/qemu-system-i386";
      qemu-system-i386.capabilities = "cap_net_admin+ep";

      qemu-system-arm.source = "${pkgs.qemu}/bin/qemu-system-arm";
      qemu-system-arm.capabilities = "cap_net_admin+ep";

    };

    services.udev.packages = [
      (pkgs.writeTextFile rec {
        name = "nemu.rules";
        destination = "/etc/udev/rules.d/98-${name}";
        text = ''
          SUBSYSTEM=="usb", MODE="0664", GROUP="usb"
          SUBSYSTEM=="macvtap", ACTION=="add", GROUP="kvm", MODE="0660"
          KERNEL=="kvm", GROUP="kvm", MODE="0660"
          KERNEL=="vhost-net", GROUP="kvm", MODE="0660", OPTIONS+="static_node=vhost-net"
        '';
      })
    ];

  };

}
