{ stdenv, config, fetchFromGitHub, cmake
, gettext, ncurses, sqlite, libusb1, libudev, qemu
, libxml2, libarchive, graphviz
, libpthreadstubs
}:

stdenv.mkDerivation rec {
  pname = "nemu";
  version = "2.2.1";

  src = fetchFromGitHub {
    owner = "0x501D";
    repo = pname;
    rev = "v${version}";
    sha256 = "1s670kfgviz6z5k79a12s4chybq04c2kpwg0iyf2rlbhrl4fkjn6";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    gettext
    graphviz
    libarchive
    libpthreadstubs
    libudev
    libusb1
    libxml2
    ncurses
    qemu
    sqlite
  ];

  cmakeFlags = [
    "-DNM_WITH_OVF_SUPPORT=ON"
    #"-DNM_SAVEVM_SNAPSHOTS=ON"  # requires patched version of QEMU, override them all if needed
    "-DNM_WITH_VNC_CLIENT=ON"
    "-DNM_WITH_SPICE=ON"
    "-DNM_WITH_NETWORK_MAP=ON"
  ];

  system.requiredKernelConfig = with config.lib.kernelConfig; [
    (isEnabled "VETH")
    (isEnabled "MACVTAP")
  ];

  preConfigure = ''
    patchShebangs .

    substituteInPlace CMakeLists.txt --replace 'USR_PREFIX "/usr"' "USR_PREFIX \"$(out)\""

    substituteInPlace src/nm_cfg_file.c --replace /bin/false /run/current-system/sw/bin/false

    substituteInPlace src/nm_cfg_file.c --replace /share/nemu/templates/config/nemu.cfg.sample \
                                                  $out/share/nemu/templates/config/nemu.cfg.sample

    substituteInPlace src/nm_cfg_file.c --replace \
'            nm_str_format(&qemu_bin, "%s/bin/qemu-system-%s",
                NM_STRING(NM_USR_PREFIX), token);' \
'            nm_str_format(&qemu_bin, "/run/wrappers/bin/qemu-system-%s", token);'

    substituteInPlace src/nm_cfg_file.c --replace "/usr/bin" /run/current-system/sw/bin

    substituteInPlace src/nm_add_vm.c --replace /bin/qemu-img ${qemu}/bin/qemu-img  # 2.2.1 only

    substituteInPlace src/nm_machine.c --replace \
'    nm_str_format(&buf, "%s/bin/qemu-system-%s",
        NM_STRING(NM_USR_PREFIX), arch);' \
'    nm_str_format(&buf, "/run/wrappers/bin/qemu-system-%s", arch);'

    substituteInPlace src/nm_add_drive.c --replace /bin/qemu-img ${qemu}/bin/qemu-img

    substituteInPlace src/nm_ovf_import.c --replace /bin/qemu-img ${qemu}/bin/qemu-img

    substituteInPlace src/nm_vm_snapshot.c --replace /bin/qemu-img ${qemu}/bin/qemu-img

    substituteInPlace src/nm_vm_control.c --replace /bin/qemu-system- ${qemu}/bin/qemu-system-

    substituteInPlace nemu.cfg.sample --replace /usr/bin /run/current-system/sw/bin

    substituteInPlace lang/ru/nemu.po --replace /bin/false /run/current-system/sw/bin/false

    substituteInPlace sh/ntty --replace /usr/bin /run/current-system/sw/bin

    #mkdir -p $out/share/bash-completion/completions
  '';

  installFlags = "DESTDIR=$(out)/";

  preInstall = ''
    install -D -m0644 -t $out/share/doc ../LICENSE
  '';

  postInstall = ''
    rm $out/share/nemu/scripts/{42-net-macvtap-perm.rules,setup_nemu_nonroot.sh}
  '';

  meta = with stdenv.lib; {
    description = "Ncurses interface for QEMU";
    homepage = https://github.com/0x501D/nemu;
    license = licenses.bsd2;
    platforms = platforms.linux; # ++ platforms.freebsd;  # freebsd support claimed but Nix testing needed
  };

}
