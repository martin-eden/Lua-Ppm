-- Load .ppm, parse it and save back

-- Last mod.: 2024-11-30

-- Config:
local Config =
  {
    InputFileName = _G.arg[1] or 'Data/Data.ppm',
    OutputFileName = _G.arg[2] or 'Data/Data.Reforged.ppm',
  }

--[[ Dev
package.path = package.path .. ';../../?.lua'
require('workshop.base')
--]]
-- [[ Use
require('workshop.base')
--]]

-- Imports:
local Ppm = request('!.concepts.Ppm.Interface')
local InputFile = request('!.concepts.StreamIo.Input.File')
local OutputFile = request('!.concepts.StreamIo.Output.File')

-- Load image from file
local LoadImageFromFile =
  function(FileName)
    local Result

    InputFile:Open(FileName)

    Ppm.Input = InputFile

    Result = Ppm:Load()

    InputFile:Close()

    return Result
  end

-- Save image to file
local SaveImageToFile =
  function(Image, FileName)
    local Result

    OutputFile:Open(FileName)

    Ppm.Output = OutputFile

    Result = Ppm:Save(Image)

    OutputFile:Close()

    return Result
  end

-- Reformat
local Reformat =
  function(InputFileName, OutputFileName)
    print(('Loading image from "%s".'):format(InputFileName))

    local Image = LoadImageFromFile(InputFileName)

    if not Image then
      print('Failed to load image.')
      return
    end

    print(('Saving image to "%s".'):format(OutputFileName))

    local IsSaved = SaveImageToFile(Image, OutputFileName)

    if not IsSaved then
      print('Failed to save image.')
      return
    end

    return true
  end

-- Exports:
do
  print('[Reforge .ppm] Started.')

  local JobDone = Reformat(Config.InputFileName, Config.OutputFileName)

  if not JobDone then
    print('Failed to do the job.')
  end

  print('[Reforge .ppm] Done.')
end

--[[
  2024-11-04
]]
