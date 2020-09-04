#!/usr/bin/env ruby
require 'chunky_png'
require 'optparse'
require 'json'

def random_seed(h,w, one_in_n_is_alive = 2)
  out = []
  h.times do
    row = []
    w.times do
      row << rand(one_in_n_is_alive) == 1 ? 1 : 0
    end
    out << row
  end

  return out
end


# scaling to png pixels
#in -> [ [1,0],
#        [1,1] ]
#
# out-> [ [1,1,1,1,0,0,0,0],
#         [1,1,1,1,0,0,0,0],
#         [1,1,1,1,0,0,0,0],
#         [1,1,1,1,0,0,0,0],
#         [1,1,1,1,1,1,1,1],
#         [1,1,1,1,1,1,1,1],
#         [1,1,1,1,1,1,1,1],
#         [1,1,1,1,1,1,1,1], ]

def print_board(title, generation, board, scale = 4)
  png = ChunkyPNG::Image.new(board.length * scale, board[0].length * scale, ChunkyPNG::Color('black @ 1.0'))
  board.each_with_index do |row, h|
    row.each_with_index do |cell, w|
      (0...scale).each do |ph|
        (0...scale).each do |pw|
          png[(h * scale) + ph, (w * scale) + pw] = (board[h][w] == 1 ? ChunkyPNG::Color('red @ 1.0') : ChunkyPNG::Color('blue @ 1.0'))
        end
      end
    end
  end
  png.save("./output/#{title}/frame_#{generation.to_s.rjust(4, "0")}.png",
           :color_mode => ChunkyPNG::COLOR_INDEXED,
           :compression => Zlib::NO_COMPRESSION,
           :interlace => true)
end

def count_live_neighbors(board, h, w)
  count = 0
  height = board.length - 1
  width = board[0].length - 1
  (-1..1).each do |relative_h|
    (-1..1).each do |relative_w|
      if [relative_w, relative_h] != [0,0] # ignore ourselves
        h2 = h + relative_h
        w2 = w + relative_w
        if (0..height).include?(h2) && (0..width).include?(w2)
         #  puts "found valid neighbor #{h2}, #{w2} (#{board[h2][w2]})"
          if board[h2][w2] == 1
            count += 1
          end
        end
      end
    end
  end

  return count
end

def next_board(board)
  # this is a cheap way to deep clone nested arrays. i should being using the Matrix class
  new_board = Marshal.load(Marshal.dump board)
  height = board.length - 1
  width = board[0].length - 1
  (0..height).each do |h|
    (0..width).each do |w|
      live_neighbor_count = count_live_neighbors(board, h, w)
      if board[h][w] == 1 # we are alive
        if live_neighbor_count < 2
          # Any live cell with fewer than two live neighbours dies, as if by underpopulation.
          new_board[h][w] = 0
        elsif live_neighbor_count == 2 || live_neighbor_count == 3
          # Any live cell with two or three live neighbours lives on to the next generation.
          new_board[h][w] = 1
        else
          # Any live cell with more than three live neighbours dies, as if by overpopulation.
          new_board[h][w] = 0
        end
      else # we are dead
        # Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        new_board[h][w] = (live_neighbor_count == 3 ? 1 : 0)
      end
    end
  end

  return new_board
end

def conway(max_generation, board, print_scale, title)
  count = 0;
  generation = 0
  puts "running generation: #{generation} / #{max_generation}"
  print_board(title, generation, board, print_scale)

  while count < max_generation do
    count += 1
    generation += 1
    puts "running generation: #{generation} / #{max_generation}"
    board = next_board(board)
    print_board(title, generation, board, print_scale)
  end
end
require 'optparse'

options = {
  title: Time.now.to_i.to_s,
  generations: 10,
  scale: 4,
  seed_scale_x: 1920 / 4,
  seed_scale_y: 1080 / 4,
  chance_one_in_n_is_alive: 2
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} -i SAMPLE_SEED.json -g 25 -s 12 -t test-run -a"

  opts.on("-t TITLE", "--title TITLE", "Title of Directory") do |opt|
    options[:title] = opt
  end

  opts.on("-s SCALE", "--scale SCALE", "Scale of pixels in output images") do |opt|
    options[:scale] = opt.to_i
  end

  opts.on("-g GENERATIONS", "--generations GENERATIONS", "How many generations to run aka how many frames to generate.") do |opt|
    options[:generations] = opt.to_i
  end

  opts.on("-x X", "--x_scale X", "Size of width of gameboard") do |opt|
    options[:seed_scale_x] = opt.to_i
  end

  opts.on("-y Y", "--y_scale Y", "Size of height of gameboard") do |opt|
    options[:seed_scale_y] = opt.to_i
  end

  opts.on("-c CHANCE", "--chance CHANCE", "Set probability that 1 in CHANCE will be alive in a random seed") do |opt|
    options[:chance_one_in_n_is_alive] = opt.to_i
  end

  opts.on("-a", "--animate", "Generate an animated mp4") do |opt|
    if !(system("which ffmpeg &"))
      puts "ffmpeg is required to generate an animated mp4"
      exit 69 # nice
    end

    options[:animate] = opt
  end

  opts.on("-i IMPORT_FILE.json", "--import IMPORT_FILE.json", "Provide a seed board as a JSON file. This should be a two dimensional array where every sub array is the same length. Use 0 for dead and 1 for alive. Eg: [[0,1],[1,0]]") do |opt|
    options[:starting_board] = opt
  end
end.parse!

if options[:starting_board]
  game_kernel = JSON.parse(File.read(options[:starting_board]))
else
  game_kernel = random_seed(
    options[:seed_scale_x],
    options[:seed_scale_y],
    options[:chance_one_in_n_is_alive]
  )
end

system("mkdir -p ./output/#{options[:title]}")

conway(
  options[:generations],
  game_kernel,
  options[:chance_one_in_n_is_alive],
  options[:title]
)

# -pix_fmt yuv420p
if options[:animate]
  puts "generating ./output/#{options[:title]}/*.png"
  system("ffmpeg -framerate 4 -pattern_type glob -i './output/#{options[:title]}/*.png' './output/#{options[:title]}/out.mp4'")
end
