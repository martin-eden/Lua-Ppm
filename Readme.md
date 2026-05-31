## What

2024, 2026

`Plain portable pixmap` format loader/saver.


## Use cases / Why

Loading/saving bitmap image without using external libraries.

Images in this formats are too large comparing to `.png` or `.jpg`
or `.gif`. But can you write discrete Fourier transformation
in one evening?

Your Lua code is not always running on fully charged Linux desktop.
It may be Raspberry Pi or even NodeMCU.

Maybe you want just generate image from scratch and save it without
mating your mind with C++ library idiosyncrasies.

Maybe you want just write some image filter without binding your
code to library.

That's the point of `.ppm` plain text format.

Installing `netpbm` (or `imagemagick`) adds tools to convert `.ppm`
to standard `.png`. That's a way to main road.


## Loading

Load `Data.ppm` as Lua table `Image`.

```Lua
local input_file_name = 'Data.ppm'

-- Imports:
local parse_netpbm = request('!.concepts.Codec_Netpbm.parse')
local InputFile = request('!.concepts.StreamIo.Input.File')

-- Load image from file
local load_image_from_file =
  function(filename)
    InputFile:Open(filename)

    local Image = parse_netpbm(InputFile)

    InputFile:Close()

    return Image
  end

local Image = load_image_from_file(input_file_name)
```


## Saving

Save Lua table `Image` to file `Data.ppm`.

```Lua
local output_file_name = 'Data.ppm'

-- Imports:
local compile_netpbm = request('!.concepts.Codec_Netpbm.compile')
local OutputFile = request('!.concepts.StreamIo.Output.File')

-- Save image to file
local save_image_to_file =
  function(filename, Image)
    OutputFile:Open(filename)

    compile_netpbm(OutputFile, Image)

    OutputFile:Close()
  end

save_image_to_file(output_file_name, Image)
```

## Command-line tool

This library is supplied with command-line script [Reforge][Reforge].

Without arguments it loads [`Data.ppm`](Data/Data.ppm), parses it
and saves to [`Data.Reforged.ppm`](Data/Data.Reforged.ppm).
Not a big deal but I value formatting in my projects:

```
P3
# Created by GIMP version 2.10.30 PNM plug-in
60 131
255
126
62
116
126
62
116
126
62
116
126
62
116
```

```
P3  # Color, text
60 131 255  # Width, Height, MaxValue

# Line 1
126 062 116  126 062 116  126 062 116  126 062 116
126 062 116  126 062 116  126 062 116  126 062 116
126 062 116  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
...
```

## Requirements

  * Lua 5.3 (or 5.4, 5.5)


## See also

* [.ppm][FormatSpec] -- Official format specification
* [`Reforge`][Reforge] -- Local script to recode data
* [`workshop`][workshop] -- My personal Lua framework where this codec lives
* [My other repositories][Repos]

[FormatSpec]: https://netpbm.sourceforge.net/doc/ppm.html
[Reforge]: Reforge.lua
[workshop]: https://github.com/martin-eden/workshop
[Repos]: https://github.com/martin-eden/contents
