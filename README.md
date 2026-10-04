# Hyprland Aquarium

## Patching imgborders

```sh
git clone https://codeberg.org/zacoons/imgborders ~/Documents/imgborders
cd ~/Documents/imgborders
git checkout 08be222
git apply fish.patch
cmake -B build
cmake --build build
```

Hyprland loads `~/Documents/imgborders/build/libimgborders.so` on startup.

## Building noise

```sh
cd ~/.config/hypr/assets
cc -O2 -o noise noise.c
```

## Credits

- **Fish images**: cut from the species illustrations on
  [Marinewise](https://marinewise.com.au/australian-fish-and-marine-species/)
- **noise1234**: Perlin noise by Stefan Gustavson
  ([stegu/perlin-noise](https://github.com/stegu/perlin-noise))
- **imgborders**: by [zacoons](https://codeberg.org/zacoons/imgborders)
