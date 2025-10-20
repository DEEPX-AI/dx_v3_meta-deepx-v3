# systemd Configuration for DEEPX V3 Platform
# Optimized for embedded ISP camera systems

# ==============================================================================
# Battery Check Package Separation
# ==============================================================================
# Create separate package for systemd-battery-check to avoid installing it
# in systems without battery (embedded camera doesn't need battery check)
PACKAGES =+ "${PN}-battery-check"
FILES:${PN}-battery-check = "${nonarch_base_libdir}/systemd/systemd-battery-check"

# ==============================================================================
# Network Configuration (Optional)
# ==============================================================================
# Uncomment to enable systemd-networkd and systemd-resolved
# PACKAGECONFIG:append = " networkd resolved"

# ==============================================================================
# Remove Unnecessary Features for Embedded Systems
# ==============================================================================
# Disable systemd features not needed in headless embedded ISP camera:
#   - backlight:         Screen brightness control (no display)
#   - hibernate:         Hibernation support (not needed)
#   - localed:           Locale/keyboard service (no UI)
#   - logind:            Login/session management (single user)
#   - machined:          VM/container management (not used)
#   - nss-mymachines:    NSS module for containers (not used)
#   - quotacheck:        Filesystem quota checking (not used)
#   - rfkill:            RF kill switch management (no wireless)
#   - utmp:              Login logging (not needed)
#   - vconsole:          Virtual console setup (serial only)
#   - xdg-autostart:     XDG autostart support (no desktop)
PACKAGECONFIG:remove = " \
    backlight \
    hibernate \
    localed \
    logind \
    machined \
    nss-mymachines \
    quotacheck \
    rfkill \
    utmp \
    vconsole \
    xdg-autostart \
"