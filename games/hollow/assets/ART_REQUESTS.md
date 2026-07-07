# Art asset requests — "Cozy Isle" (and shared sprites)

These are the sprites the games load from `assets/textures/<name>.png`. The game
currently ships with **procedural placeholder** art (from `tools/gen_world.py`,
`tools/gen_sprites.py`, `tools/gen_textures.py`). To upgrade the look, generate
each item below (AI or hand-drawn) and **drop it in with the exact same filename
and pixel size** — the game picks it up with no code change.

## Global style
- **Cute / kawaii**, soft rounded shapes, warm pastel palette, gentle shading,
  thick soft outline. Cohesive "Animal Crossing / cozy mobile game" look.
- **Transparent background (PNG, RGBA)**. Subject centered, small padding.
- Flat top-down-ish 3/4 view, single subject per file, no ground/scene baked in.
- Deliver at the exact pixel size listed (or an exact 2×/3× multiple, same aspect).

## Cozy Isle (game #7)
| file | size (px) | prompt |
|------|-----------|--------|
| `villager.png` | 48×44 | a tiny round kawaii animal villager, big shiny eyes, rosy cheeks, small smile, little round ears, pastel blue-lilac body, soft outline, facing the camera |
| `tree.png` | 72×92 | a cute stylized fruit tree, fat rounded fluffy green canopy in soft clusters, short chubby brown trunk, three small red apples, gentle shading |
| `rock.png` | 48×38 | a cute smooth grey boulder, softly rounded, subtle top highlight, tiny moss speck, friendly not sharp |
| `flower.png` | 32×32 | a cute five-petal flower seen from above, soft pink petals, bright yellow center, glossy, minimal |
| `decor_fence.png` | 42×30 | a cute short wooden fence segment, warm light-wood planks, rounded tops |
| `decor_lamp.png` | 42×48 | a cozy little garden lamp post, warm glowing yellow lantern, soft metal, gentle glow |
| `decor_path.png` | 42×30 | a cute stone path tile, pale rounded cobbles, soft |
| `decor_bench.png` | 48×34 | a cute wooden park bench, warm wood, rounded, small |
| `decor_flowerbed.png` | 44×30 | a cute flowerbed, cluster of tiny pink & yellow flowers in soft soil, top-down |
| `ground_grass.png` | 64×64 (tileable) | a soft seamless cartoon grass texture, gentle green, subtle blades, tileable |

> The `decor_*.png` files now exist (AI-generated) and `world.lua` places them
> directly per recipe. `ground_grass.png` also exists but is not wired yet —
> the ground is a single stretched sprite, so tiling it needs texture-repeat
> support in Rust (otherwise a 64×64 tile stretched full-screen looks blocky).

## Space Shooter (game #6) — already high-res, optional upgrade
| file | size (px) | prompt |
|------|-----------|--------|
| `ship.png` | 48×48 | a cute chunky retro player spaceship, metallic teal-blue, glowing cyan cockpit, small engine flame, top-down, pointing up |
| `alien.png` | 44×44 | a cute glowing green space cephalopod/alien, bright yellow-green glowing core, wavy tentacle lobes, two little eyes |
| `shot.png` | 8×22 | a soft glowing cyan laser bolt, white core |

## Shared (used by several games)
| file | size (px) | prompt |
|------|-----------|--------|
| `orb.png` | 32×32 | a glossy soft sphere, grayscale/white so it can be tinted (ball, bullet, gem) |
| `food.png` | 24×24 | a cute shiny red apple with a small green leaf |
| `gem.png` | 16×16 | a cute glowing teal gem/diamond |
| `pony.png` | 48×48 | a cute chibi pony, chestnut-brown body, cream blaze, caramel mane, side view (Pony Parade piece + menu icon) |
| `icon_*.png` | 40–64 | Pony Parade HUD icons (heart/coin/bolt/trophy/clock/bulb/trash/find/eye/pin) — see tools/floniks_manifest.json |

## Notes for generation
- Prefer a **consistent art direction across all files** (same outline weight,
  palette, lighting) so the collection feels unified.
- Keep important detail away from the very edges (a few px margin).
- If a tool outputs a background, remove it (true alpha, not white).

## Midnight Gallery (game #12 — mild-horror interrogation VN)
Portraits are a different pipeline from the kawaii bible: Floniks nano-banana-pro
text-to-image base portraits, then **image_to_image** expression variants (calm /
tense / frightened) off each base for character consistency; the eerie backdrop is
an i2i of the clean gallery scene. Voice: Floniks minimax TTS, one **fixed per-character
timbre** (pitch/formant profile) so each witness sounds distinct. Ambient loop: Floniks
Lyria 2.
| file | notes |
|------|-------|
| `vg_coach{,_t,_f}.png` | 林薇 网球教练 — calm / tense / frightened |
| `vg_ol{,_t,_f}.png` | 苏晴 会计 — calm / tense / frightened |
| `vg_teacher{,_t,_f}.png` | 陈墨 讲师 — calm / tense / frightened |
| `vg_gallery.png` / `vg_gallery_dark.png` | clean scene / the "凝视者" appears |
| `audio/vo_{coach,ol,teacher}.wav` | fixed-timbre witness voice (opening lines) |
| `audio/gallery.wav` | dark-ambient BGM loop |
