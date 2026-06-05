{ ... }:

{
  services.zapret = {
    enable = true;
    params = [
      "--dpi-desync=fake,disorder2"
      "--dpi-desync-ttl=1"
      "--dpi-desync-autottl=2"
      "--dpi-desync-fooling=md5sig"
    ];
    httpSupport = true;
    udpSupport = true;
    udpPorts = [
      "443"
      "50000:50100"
    ];
  };
}
