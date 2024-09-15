# Group of scripts used by SFENCE and which are connected to Minetest

## License

### Source code

BSD 2.0, see LICENSE file when license in not included in file header

### Media:

Copyright (c) 2024 SFENCE (CC BY-SA 4.0):
All textures not mentioned below.

Neuromancer (CC BY-SA 3.0):
  `default_cobble.png` - copied from Minetest game
  `default_mossycobble.png` - copied from Minetest game

## Scripts

### Generate combine texture

If you have original texture and texture generated from original one by combination with another texture, you can use this script to estimate possible texture used for combination.
	`python3 generate_combine_texture.py test_out/combine_mossy.png test_in/default_mossycobble.png test_in/default_cobble.png`

### Generate game bash script

This script will take your game and try to generate bash script which will use GIT and contentdb to regenerate identical game. It includes all enabled mods.
	`python3 generate_game_bash_script.py `

### Generate random texture

This script generate random texture from mask picture and palette texture.

Each pixel with alpha > 0 from mask picture is replaced random color from palette.
If palette layers file is used, one color from mask picture have to use same palete layer. Palette layer is defined by same color space in palette layers file. This space match with space in palette file where color for replace is defined.
Final picture can be optionaly combined with combine picture.
  `python3 generate_random_texture.py test_out/output.png test_in/full_4x4.png palette_4x4.png NO NO 56`
  `python3 generate_random_texture.py test_out/output.png test_in/full_4x4.png test_in/palette_4x4.png test_in/layers_4x4.png NO 56`
  `python3 generate_random_texture.py test_out/output.png test_in/full_4x4.png palette_4x4.png NO test_in/combine_4x4.png 56`

### Generate moss stages

This script can be used to generate flora stages from flora similar to moss. 
	`python3 generate_moss_stages.py test_out/moss_{}.png test_in/moss.png 5 5 0 NO test_out/group.png`
	`python3 generate_moss_stages.py test_out/moss_{}.png test_in/moss.png 5 5 5 test_in/moss_stages.png test_out/group.png`

### Generate flora stages

This script can be used to generate flora stages from flora similar to flower. 
	`python3 generate_flora_stages.py test_out/flower_{}.png test_in/flower.png NO grass 5 5 0 test_in/flower_stages.png test_out/group.png 5`
	`python3 generate_flora_stages.py test_out/flower_{}.png test_in/flower.png NO grass 5 5 5 test_in/flower_stages.png test_out/group.png 5`

## Specific requirements

### MacOS

If you use python from brew package system, this python version does not support pip.

But you can create separate python env where pip works:

```
python -m venv sklearn-env
source sklearn-env/bin/activate  # activate
pip install -U scikit-learn
```

