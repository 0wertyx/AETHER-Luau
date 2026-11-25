# AETHER: publishable animation library

Use this only in a Roblox experience you own or are developing with permission.

## Export
Sync the AETHER Rojo project in Studio Edit mode. Insert an R6 reference rig named R6 and an R15 reference rig named R15 in Workspace. Open View > Command Bar. Run:

```lua
local M = require(game.ReplicatedStorage.Aether.MotionStudio)
M.exportLibrary(workspace.R6, {fps=60, intensity=65, origin=100})
M.exportLibrary(workspace.R15, {fps=60, intensity=65, origin=100})
```

The exporter reads the existing live-pose evaluator and emits 616 possible sequences (44 styles × 7 states × 2 rigs). No asset IDs are invented. To test a small batch first:

```lua
M.exportLibrary(workspace.R15, {styles={"Natural"}, states={"Idle","Walk","Run"}, fps=60})
```

Sequences go into ServerStorage/AetherAnimationExports/<rig>/<style>/<state>. Publish them via Studio's animation publishing workflow as the creator or group that owns the experience. Set each published ID in the matching ReplicatedStorage/AetherAnimationLibrary/<rig>/<style>/<state> Animation object's AnimationId property (rbxassetid://NUMBER). Save/publish the experience. Use the standard server-created Humanoid Animator.

In AETHER > Character > Motion Studio > Playback Mode, select Replicated, enable the pack, and Confirm All. Local fallback is shown if an asset is missing or fails to load. Playback uses the standard Animator and the existing state/speed selection.

## Fidelity limits
Frames are sampled from the same joint target function at the requested rate, including R15 retargeting and ground correction for the reference rig. Intensity, origin and prop-related lift are baked; re-export and republish when changing those values or the target rig proportions. Existing published Animation IDs are not overwritten by the exporter. A finite clip cannot exactly reproduce unbounded procedural motion, adaptive phase continuity or all loop seams. Harpy Glide's live jump/fall timeline is split into separate clips; particles, props, visibility effects and preview camera transforms are not animation tracks. No upload or runtime test has been performed here.
