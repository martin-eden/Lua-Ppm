## What

(2024-11)

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
local InputFileName = 'Data.ppm'

-- Imports:
local Ppm = request('Ppm.Interface')
local InputFile = request('!.concepts.StreamIo.Input.File')

-- Load image from file
local LoadImageFromFile =
  function(FileName)
    local Result

    InputFile:OpenFile(FileName)

    Ppm.Input = InputFile

    Result = Ppm:Load()

    InputFile:CloseFile()

    return Result
  end

local Image = LoadImageFromFile(InputFileName)
```

Note that we're plugging input stream to codec: `Ppm.Input = InputFile`.
So codec does not care what that stream is: string, pipe or file.


## Saving

Saving is similar to loading. But stream connection point is named
`.Output`. And method is unsurprisingly named `Save`.


## Lua image format

That's the structure of Lua table returned by `Load()` method:

```
(
  (
    (
      [1] = float_ui // aka .Red
      [2] = float_ui // aka .Green
      [3] = float_ui // aka .Blue
    ) ^ Width
  ) ^ Height
)
```

Color component values are floats in unit interval [0.0, 1.0].
Basically color is list of three floats. But indices of this list
are aliased: `Red` for index 1, `Green` for 2, `Blue` for three.

We don't provide image matrix's width and height. You can always
calculate it by using Lua's `#`: height is `#Image`, width is
length of any line, let it be line 1: width is `#Image[1]`.


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
P3  # Plain portable pixmap
60 131 255  # Width, Height, Max color component value

126 062 116  126 062 116  126 062 116  126 062 116
126 062 116  126 062 116  126 062 116  126 062 116
126 062 116  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106
084 042 106  084 042 106  084 042 106  084 042 106

126 062 116  126 062 116  126 062 116  126 062 116
084 042 106  084 042 106  084 042 106  084 042 106
...
```

## Requirements

  * Lua 5.4

It does not use any OS-specific functions so may run even under Windows!


## See also

* [.ppm format specification][FormatSpec]
* [Abstracted I/O specification][StreamIo]
* [Data values formatting][DataValuesFormatting]
* [Data strings formatting][DataStringsFormatting]
* ["Reforge", CLI script][Reforge]
* [My other repositories][Repos]

[FormatSpec]: https://netpbm.sourceforge.net/doc/ppm.html
[StreamIo]: https://github.com/martin-eden/workshop/tree/master/concepts/StreamIo
[DataValuesFormatting]: Ppm/Compiler_LuaToIs/Interface.lua
[DataStringsFormatting]: Ppm/Compiler_IsToPpm/Interface.lua
[Reforge]: Reforge.lua

[Repos]: https://github.com/martin-eden/contents
