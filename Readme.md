## What

| Created | Updated |
|:-------:|:-------:|
| 2024    | 2026-06 |

`Plain portable pixmap` codec.


## Use cases / Why

☑ It's simple and conscious text format. Fun to implement

☑ Loading/saving bitmap image without using external libraries

☑ Image files are human-readable and editable text files

☐ Compact data

  Images in this formats are too large comparing to `.png` or `.gif`.

☐ Wide support

  It's not widely used.

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
  function(Image, filename)
    OutputFile:Open(filename)

    compile_netpbm(Image, OutputFile)

    OutputFile:Close()
  end

save_image_to_file(Image, output_file_name)
```

## Internal image data format

For given `.ppm` data
```
P3
1 2 255
0 128 255 128 255 0
```

Lua image table is
```lua
{
  Settings =
    {
      Width = 1,
      Height = 2,
      ColorFormat = 'rgb',
    },
  Data =
    {
      [1] = { [1] = { 0.0, 0.5, 1.0 } },
      [2] = { [1] = { 0.5, 1.0, 0.0 } },
    },
}
```

## Command-line tool

This repository is supplied with command-line script [Reforge][Reforge].

It does full parse-convert-convert-compile cycle and internally serves as a test.

It recompiles `.ppm` file, effectively removing all existing comments and redundant data.

Externally it may be used as data beautifier.

It's used as `$ lua Reforge.lua [ <input_file> <output_file> ]`.

Without arguments it loads [`Data.ppm`](Data/Data.ppm), parses it
and saves to [`Data.Reforged.ppm`](Data/Data.Reforged.ppm).

I value formatting in my projects:

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
```
→
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

  * Linux (file loading tools assume POSIX filesystem)
  * Lua 5.3 (or 5.4, 5.5)


## Install/remove

* Clone repo


## See also

* [.ppm][FormatSpec] -- Official format specification
* [`Reforge`][Reforge] -- Local script to recode data
* [`workshop`][workshop] -- My personal Lua framework where this codec lives
* [My other projects][contents]

[FormatSpec]: https://netpbm.sourceforge.net/doc/ppm.html
[Reforge]: Reforge.lua
[workshop]: https://github.com/martin-eden/workshop
[contents]: https://github.com/martin-eden/contents
