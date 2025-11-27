#
# DEEPX Image Validation Class
#
# Validates that the configured init manager matches the image requirement.
# This class prevents build errors by skipping incompatible images early in
# the parsing phase.
#
# Usage:
#   In your image recipe (.bb file):
#
#   REQUIRED_INIT_MANAGER = "systemd"
#   inherit deepx-image-validate
#
# Variables:
#   REQUIRED_INIT_MANAGER - Required init manager ("systemd" or "busybox")
#
# Behavior:
#   - If REQUIRED_INIT_MANAGER matches VIRTUAL-RUNTIME_init_manager: Continue
#   - If they don't match: Skip recipe with informative message
#   - If REQUIRED_INIT_MANAGER is not set: No validation (continue)
#
# Example:
#   For a systemd-only image:
#     REQUIRED_INIT_MANAGER = "systemd"
#     inherit deepx-image-validate
#
#   For a busybox-only image:
#     REQUIRED_INIT_MANAGER = "busybox"
#     inherit deepx-image-validate
#

python () {
    """
    Validate init manager compatibility.

    This function runs during recipe parsing and validates that the configured
    init manager matches the image requirement. If there's a mismatch, the
    recipe is skipped instead of causing a build failure.

    Returns:
        None

    Raises:
        bb.parse.SkipRecipe: If init manager doesn't match requirement
    """
    # Get configured init manager (cache the result)
    init_manager = d.getVar('VIRTUAL-RUNTIME_init_manager')

    # Get required init manager for this image
    required = d.getVar('REQUIRED_INIT_MANAGER')

    # If no requirement set, skip validation
    if not required:
        return

    # Validate init manager is set
    if not init_manager:
        bb.warn("VIRTUAL-RUNTIME_init_manager not set, using default 'systemd'")
        init_manager = "systemd"

    # Check compatibility
    if init_manager != required:
        pn = d.getVar('PN')
        msg = (
            f"Image '{pn}' requires VIRTUAL-RUNTIME_init_manager='{required}' "
            f"but '{init_manager}' is configured. Skipping this image. "
            f"To build this image, set VIRTUAL-RUNTIME_init_manager='{required}' "
            f"in your configuration."
        )
        raise bb.parse.SkipRecipe(msg)
}
