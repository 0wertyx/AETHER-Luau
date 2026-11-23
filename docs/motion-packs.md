# AETHER: original pack-inspired locomotion (R6 + R15)

This document describes AETHER's **original procedural interpretations**, not
Roblox's purchased animations. There are **no animation asset IDs**, keyframes
or copyrighted animations copied from the original packs.

## Inspiration and visual direction

| AETHER style | Movement direction |
| --- | --- |
| Toy | Stiff toy-like marching and small geometric steps |
| Robot | Segmented, deliberately mechanical rhythm |
| Ninja | Forward-leaning silent runs, trailing arms |
| Bubbly | Upbeat bouncing gait and side-to-side motion |
| Stylish | Graceful asymmetrical sways and subtle torso turns |
| Mage | Suspended spellcaster-style drift |
| Levitation | Slow floating, outstretched arms, soft foot motion |
| Oldschool | Classic straightforward block-limb swing |
| Vampire | Theatrical posture and calm, slightly hunched stride |
| Astronaut | Low-gravity, slow soft motions |
| Zombie | Slow uneven shuffle and leaning posture |
| Cartoony | Exaggerated rhythmic bouncing and arms |

## Behavior

- The **Character → Custom walking animation** setting must be turned **ON**.
- In Character, choose a style with the dedicated chip gallery or **Walking style**.
- **Walking intensity %** blends the animation into Roblox's existing Animator
  track; reducing it should keep compatibility with many custom experiences.
- Styles use `MotionPacks.luau` profile data and
  `WalkMotion.luau` additive `Motor6D.Transform` animation.
- R6 is animated through RootJoint, hips, shoulders and neck.
  R15 also uses elbows, knees, ankles and waist where available.
- Movement responds to standing idle, walk/run, jump, freefall, climbing and
  swimming without replacing Roblox AnimationIds or custom Animator tracks.
- No physics changes, flight ability or server-side movement overrides.
- Studio preview mannequins are decorative anchored geometry; check actual
  body motion with an R6 and R15 player character.
- If your experience supplies very different default animations,
  reduce the intensity or disable the overlay.

The official Roblox Creator Hub documents animation packs as seven related
locomotion states (walk, run, idle, jump, fall, swim and climb):
https://create.roblox.com/docs/avatar/animation-packs

## Build

```sh
python tools/build.py
python tools/build.py --check
```

The GitHub Actions workflow automatically updates
`dist/AETHER.client.luau` when modules change. Roblox Studio runtime tests
are still required to verify pose directions across different avatar rigs.
