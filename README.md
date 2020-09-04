This is a very raw implentation of conways game of life in ruby. 

```
Usage: ./conway.rb -i SAMPLE_SEED.json -g 25 -s 12 -t test-run -a
    -t, --title TITLE                Title of Directory
    -s, --scale SCALE                Scale of pixels in output images
    -g, --generations GENERATIONS    How many generations to run aka how many frames to generate.
    -x, --x_scale X                  Size of width of gameboard
    -y, --y_scale Y                  Size of height of gameboard
    -c, --chance CHANCE              Set probability that 1 in CHANCE will be alive in a random seed
    -a, --animate                    Generate an animated mp4
    -i, --import IMPORT_FILE.json    Provide a seed board as a JSON file. This should be a two dimensional array where every sub array is the same length. Use 0 for dead and 1 for alive. Eg: [[0,1],[1,0]]
```

### run and animate using a JSON seed file @ 25 generations:

```
./conway.rb -i SAMPLE_SEED.json -g 25 -s 12 -t test-run -a
```

### run a 5000x5000 random simulation @ 3 generations with no animation:

```
./conway.rb -x 5000 -y 5000 -g 3 -t 5000x5000 
```