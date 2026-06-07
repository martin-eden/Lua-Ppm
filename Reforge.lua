-- Load .ppm, parse it and save back

--[[
  Author: Martin Eden
  Last mod.: 2026-06-07
]]

-- Config:
local Config =
  {
    input_file_name = _G.arg[1] or 'Data/Data.ppm',
    output_file_name = _G.arg[2] or 'Data/Data.Reforged.ppm',
  }

--[[ Dev
package.path = package.path .. ';../../?.lua'
--]]
require('workshop.base')

-- Imports:
local parse_netpbm = request('!.concepts.codec_netpbm.parse')
local compile_netpbm = request('!.concepts.codec_netpbm.compile')
local InputFile = request('!.concepts.StreamIo.Input.File')
local OutputFile = request('!.concepts.StreamIo.Output.File')

-- Load image from file
local load_image_from_file =
  function(filename)
    InputFile:Open(filename)

    local Image = parse_netpbm(InputFile)

    InputFile:Close()

    return Image
  end

-- Save image to file
local save_image_to_file =
  function(Image, filename)
    OutputFile:Open(filename)

    compile_netpbm(Image, OutputFile)

    OutputFile:Close()
  end

-- Reformat
local reformat =
  function(input_file_name, output_file_name)
    print(string.format('Loading image from "%s".', input_file_name))

    local Image = load_image_from_file(input_file_name)

    if not Image then
      print('Failed to load image.')
      return
    end

    print(string.format('Saving image to "%s".', output_file_name))

    save_image_to_file(Image, output_file_name)
  end

-- ( [Main]
print('[Reforge .ppm] Started.')

reformat(Config.input_file_name, Config.output_file_name)

print('[Reforge .ppm] Done.')
-- )

--[[
  2024
  2026-05-31
]]
