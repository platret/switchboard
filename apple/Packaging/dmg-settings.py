# dmgbuild settings for the Switchboard disk image. make-dmg.sh runs:
#
#   uvx --from dmgbuild==<version> dmgbuild -s apple/Packaging/dmg-settings.py \
#     -D app=<path to Switchboard.app> -D background=<path to dmg-background.tiff> \
#     Switchboard <output.dmg>
#
# The icon positions are the centres of the two slots drawn in dmg-background.html (660 x 420).
import os.path

application = defines.get("app", "Switchboard.app")  # noqa: F821 (provided by dmgbuild)
app_name = os.path.basename(application)
# The mounted volume shows the app icon on the desktop and in the Finder sidebar.
icon = os.path.join(application, "Contents", "Resources", "AppIcon.icns")

# Volume
format = "ULFO"  # lzfse, macOS 10.11 and later
filesystem = "HFS+"
size = None  # computed from the contents
files = [application]
symlinks = {"Applications": "/Applications"}
# No hide_extensions: it sets com.apple.FinderInfo on the app, which breaks
# `codesign --verify --strict` on the copy in the image. Finder hides ".app" anyway.
hide_extensions = []

# Icons
icon_locations = {
    app_name: (170, 190),
    "Applications": (490, 190),
}
icon_size = 128
text_size = 13
label_pos = "bottom"
arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)

# Window
background = defines.get("background", "apple/Packaging/dmg-background.tiff")  # noqa: F821
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 180
window_rect = ((200, 120), (660, 420))
default_view = "icon-view"
show_icon_preview = False
include_icon_view_settings = True
include_list_view_settings = False
