-- Original AETHER locomotion interpretations.
-- Inspiration: Roblox avatar animation packs; not their copyrighted keyframes or assets.
-- Values are modest additive offsets so games retain their own Animator tracks.
local P={}
P.order={"Toy","Robot","Ninja","Bubbly","Stylish","Mage","Levitation","Oldschool","Vampire","Astronaut","Zombie","Cartoony"}
P.profiles={
 Toy={cadence=7.6,stride=.25,arms=.31,rest=.07,spread=.04,lean=-.015,roll=.025,bob=.042,knee=.08,ankle=.05,twist=.02,snap=.48},
 Robot={cadence=6.4,stride=.19,arms=.27,rest=-.14,spread=.02,lean=.04,roll=.00,bob=.018,knee=.07,ankle=.02,twist=.015,snap=.78},
 Ninja={cadence=10.2,stride=.31,arms=.12,rest=-.38,spread=.10,lean=.18,roll=.035,bob=.024,knee=.22,ankle=.09,twist=.07,snap=.04},
 Bubbly={cadence=7.4,stride=.20,arms=.34,rest=.08,spread=.16,lean=-.05,roll=.13,bob=.115,knee=.16,ankle=.12,twist=.10,snap=.00},
 Stylish={cadence=6.1,stride=.21,arms=.23,rest=-.025,spread=.065,lean=-.055,roll=.10,bob=.055,knee=.10,ankle=.07,twist=.13,snap=.00},
 Mage={cadence=4.3,stride=.10,arms=.13,rest=-.16,spread=.34,lean=-.055,roll=.06,bob=.045,hover=.13,knee=.22,ankle=.09,twist=.045,snap=.00},
 Levitation={cadence=3.5,stride=.08,arms=.09,rest=-.20,spread=.40,lean=.065,roll=.06,bob=.04,hover=.21,knee=.27,ankle=.14,twist=.07,snap=.00},
 Oldschool={cadence=7.3,stride=.30,arms=.31,rest=.00,spread=.00,lean=.00,roll=.00,bob=.024,knee=.00,ankle=.00,twist=.00,snap=.00},
 Vampire={cadence=5.8,stride=.19,arms=.19,rest=-.21,spread=.20,lean=-.085,roll=.06,bob=.033,knee=.10,ankle=.06,twist=.09,snap=.00},
 Astronaut={cadence=4.4,stride=.15,arms=.17,rest=-.06,spread=.15,lean=.028,roll=.07,bob=.045,hover=.09,knee=.16,ankle=.08,twist=.035,snap=.00},
 Zombie={cadence=5.1,stride=.19,arms=.08,rest=.28,spread=.08,lean=.21,roll=.11,bob=.035,knee=.10,ankle=.04,twist=.065,snap=.22},
 Cartoony={cadence=8.8,stride=.29,arms=.38,rest=.055,spread=.14,lean=.02,roll=.13,bob=.13,knee=.24,ankle=.13,twist=.12,snap=.00},
}
function P.get(name) return P.profiles[name] end
return P
