{ pkgs, ... }:

{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 48000 ];
        "default.clock.quantum" = 512;
        "clock.power-of-two-quantum" = true;
      };
      "stream.properties" = {
        "resample.quality" = 8;
        "resample.disable" = false;
        "webrtc-audio-processing.enable" = true;
        "webrtc-audio-processing.echo-cancellation" = true;
        "webrtc-audio-processing.noise-suppression" = true;
      };
    };

    extraConfig.pipewire-pulse = {
      "pulse.properties" = {
        "pulse.min.req" = "128/48000";
        "pulse.default.req" = "256/48000";
        "pulse.max.req" = "1024/48000";
        "pulse.min.quantum" = "128/48000";
        "pulse.max.quantum" = "1024/48000";
      };
      "stream.properties" = {
        "resample.quality" = 10;
        "channelmix.normalize" = true;
        "channelmix.mix-lfe" = true;
        "webrtc-audio-processing.enable" = true;
        "webrtc-audio-processing.echo-cancellation" = true;
        "webrtc-audio-processing.noise-suppression" = true;
      };
    };
  };

  services.pipewire.wireplumber.configPackages = [
    (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
      bluez_monitor.properties = {
        ["bluez5.roles"] = "[ a2dp_sink hfp_hf ]";
        ["bluez5.enable-sbc-xq"] = true;
        ["bluez5.enable-msbc"] = true;
        ["bluez5.auto-connect"] = "[ a2dp_sink hfp_hf ]";
        ["bluez5.enable-hw-volume"] = true;
      }
    '')
  ];

  environment.systemPackages = with pkgs; [
    sbc
  ];
}
