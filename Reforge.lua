-- Load .ppm, parse it and save back

--[[
  Author: Martin Eden
  Last mod.: 2026-05-31
]]

-- Config:
local Config =
  {
    input_file_name = _G.arg[1] or 'Data/Data.ppm',
    output_file_name = _G.arg[2] or 'Data/Data.Reforged.ppm',
  }

--[[ Dev
package.path = package.path .. ';../../?.lua'
require('workshop.base')
--]]
-- [[ Use
require('workshop.base')
--]]

-- Imports:
local parse_netpbm = request('!.concepts.Codec_Netpbm.parse')
local compile_netpbm = request('!.concepts.Codec_Netpbm.compile')
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
  function(filename, Image)
    OutputFile:Open(filename)

    local is_done = compile_netpbm(OutputFile, Image)

    OutputFile:Close()

    return is_done
  end

-- Reformat
local reformat =
  function(input_file_name, output_file_name)
    print(('Loading image from "%s".'):format(input_file_name))

    local Image = load_image_from_file(input_file_name)

    if not Image then
      print('Failed to load image.')
      return
    end

    print(('Saving image to "%s".'):format(output_file_name))

    save_image_to_file(output_file_name, Image)
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
