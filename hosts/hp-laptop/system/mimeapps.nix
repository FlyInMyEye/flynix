{ ... }:

let
  # ─── Default applications ──────────────────────────────────────────
  # Change these to switch all associated MIME types at once
  fileManager    = "nemo.desktop";
  imageViewer    = "qimgv.desktop";
  videoPlayer    = "vlc.desktop";
  audioPlayer    = "vlc.desktop";
  archiveManager = "xarchiver.desktop";
  webBrowser     = "firefox.desktop";
  textEditor     = "kitty.desktop";
in {
  home-manager.sharedModules = [
    ({ lib, ... }: {
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          # Directories
          "inode/directory"            = fileManager;
          "x-scheme-handler/file"      = fileManager;

          # Images
          "image/avif"                 = imageViewer;
          "image/bmp"                  = imageViewer;
          "image/gif"                  = imageViewer;
          "image/jpeg"                 = imageViewer;
          "image/jpg"                  = imageViewer;
          "image/png"                  = imageViewer;
          "image/svg+xml"              = imageViewer;
          "image/tiff"                 = imageViewer;
          "image/webp"                 = imageViewer;
          "image/x-bmp"                = imageViewer;
          "image/x-png"                = imageViewer;
          "image/x-portable-anymap"    = imageViewer;
          "image/x-portable-bitmap"    = imageViewer;
          "image/x-portable-graymap"   = imageViewer;
          "image/x-portable-pixmap"    = imageViewer;
          "image/x-tga"                = imageViewer;

          # Archives
          "application/gzip"           = archiveManager;
          "application/x-7z-compressed" = archiveManager;
          "application/x-bzip"         = archiveManager;
          "application/x-bzip2"        = archiveManager;
          "application/x-rar"          = archiveManager;
          "application/x-tar"          = archiveManager;
          "application/x-xz"           = archiveManager;
          "application/x-zstd"         = archiveManager;
          "application/zip"            = archiveManager;
          "application/zstd"           = archiveManager;

          # Video
          "video/avi"                  = videoPlayer;
          "video/mp4"                  = videoPlayer;
          "video/mpeg"                 = videoPlayer;
          "video/ogg"                  = videoPlayer;
          "video/quicktime"            = videoPlayer;
          "video/webm"                 = videoPlayer;
          "video/x-avi"                = videoPlayer;
          "video/x-matroska"           = videoPlayer;
          "video/x-ms-wmv"             = videoPlayer;
          "video/x-msvideo"            = videoPlayer;

          # Audio
          "audio/aac"                  = audioPlayer;
          "audio/flac"                 = audioPlayer;
          "audio/mp4"                  = audioPlayer;
          "audio/mpeg"                 = audioPlayer;
          "audio/ogg"                  = audioPlayer;
          "audio/opus"                 = audioPlayer;
          "audio/wav"                  = audioPlayer;
          "audio/webm"                 = audioPlayer;
          "audio/x-flac"               = audioPlayer;
          "audio/x-matroska"           = audioPlayer;
          "audio/x-mp3"                = audioPlayer;
          "audio/x-ms-wma"             = audioPlayer;
          "audio/x-wav"                = audioPlayer;

          # Web
          "text/html"                  = webBrowser;
          "x-scheme-handler/about"     = webBrowser;
          "x-scheme-handler/http"      = webBrowser;
          "x-scheme-handler/https"     = webBrowser;
          "x-scheme-handler/unknown"   = webBrowser;

          # Text
          "text/plain"                 = textEditor;
        };
      };

      home.activation.makeMimeAppsWritable = lib.hm.dag.entryAfter ["linkGeneration"] ''
        MIMEAPPS="$HOME/.config/mimeapps.list"
        if [ -L "$MIMEAPPS" ]; then
          MIMEAPPS_TARGET=$(readlink -f "$MIMEAPPS")
          $DRY_RUN_CMD rm -f "$MIMEAPPS"
          $DRY_RUN_CMD cp -f "$MIMEAPPS_TARGET" "$MIMEAPPS"
          $DRY_RUN_CMD chmod u+w "$MIMEAPPS"
        fi
      '';
    })
  ];
}
