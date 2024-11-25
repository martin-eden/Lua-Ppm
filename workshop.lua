local Modules = {
  ['workshop.base'] = [=[
--[[
  Lua base libraries extension. Used almost in any piece of my code.

  This module installs global function "request" which is based on
  "require" and makes possible relative module names.

  Also this function tracks module dependencies. This allows to
  get dependencies list for any module. Which is used to create
  deploys without unused code.

  Price for tracking dependencies  is global table "dependencies"
  and function "get_require_name".

  Lastly, global functions are added for convenience. Such functions
  are "new" and families of "is_<type>" and "assert_<type>".
]]

-- Last mod.: 2024-03-02

-- Export request function:
local split_name =
  function(qualified_name)
    local prefix_name_pattern = '^(.+%.)([^%.]+)$'  -- a.b.c --> (a.b.) (c)
    local prefix, name = qualified_name:match(prefix_name_pattern)
    if not prefix then
      prefix = ''
      name = qualified_name
      if not name:find('^([^%.]+)$') then
        name = ''
      end
    end
    return prefix, name
  end

local unite_prefixes =
  function(base_prefix, rel_prefix)
    local init_base_prefix, init_rel_prefix = base_prefix, rel_prefix
    local list_without_tail_pattern = '(.+%.)[^%.]-%.$' -- a.b.c. --> (a.b.)
    local list_without_head_pattern = '[^%.]+%.(.+)$' -- a.b.c. --> (b.c.)
    while rel_prefix:find('^%^%.') do
      if (base_prefix == '') then
        error(
          ([[Link "%s" is outside caller's prefix "%s".]]):format(
            init_rel_prefix,
            init_base_prefix
          )
        )
      end
      base_prefix = base_prefix:match(list_without_tail_pattern) or ''
      rel_prefix = rel_prefix:match(list_without_head_pattern) or ''
    end
    return base_prefix .. rel_prefix
  end

local names = {}
local depth = 1

local get_caller_prefix =
  function()
    local result = ''
    if names[depth] then
      result = names[depth].prefix
    end
    return result
  end

local get_caller_name =
  function()
    local result = 'anonymous'
    if names[depth] then
      result = names[depth].prefix .. names[depth].name
    end
    return result
  end

local push =
  function(prefix, name)
    depth = depth + 1
    names[depth] = {prefix = prefix, name = name}
  end

local pop =
  function()
    depth = depth - 1
  end

local dependencies = {}
local add_dependency =
  function(src_name, dest_name)
    dependencies[src_name] = dependencies[src_name] or {}
    dependencies[src_name][dest_name] = true
  end

local base_prefix = split_name((...))

local get_require_name =
  function(qualified_name)
    local is_absolute_name = (qualified_name:sub(1, 2) == '!.')
    if is_absolute_name then
      qualified_name = qualified_name:sub(3)
    end
    local prefix, name = split_name(qualified_name)
    local caller_prefix =
      is_absolute_name and base_prefix or get_caller_prefix()
    prefix = unite_prefixes(caller_prefix, prefix)
    return prefix .. name, prefix, name
  end

local request =
  function(qualified_name)
    local src_name = get_caller_name()

    local require_name, prefix, name = get_require_name(qualified_name)

    push(prefix, name)
    local dest_name = get_caller_name()
    add_dependency(src_name, dest_name)
    local results = table.pack(require(require_name))
    pop()

    return table.unpack(results)
  end

local IsFirstRun = (_G.request == nil)

if IsFirstRun then
  _G.request = request
  _G.dependencies = dependencies
  _G.get_require_name = get_require_name

  --[[
    At this point we installed "request()", so it's usable from
    outer code.

    Below we call optional modules which install additional
    global functions.

    Functions made global because they are widely used in my code.

    They are inside other files. We use freshly added "request()"
    to load them and add them to dependencies of this module.

    We need add record to call stack with our name because these
    calls of "request()" are inside "if", so the call will not be
    done until actual execution.
  ]]

  -- First element is invocation module name, second - module file path
  local our_require_name = (...)

  push('', our_require_name)

  request('!.system.install_is_functions')()
  request('!.system.install_assert_functions')()
  _G.new = request('!.table.new')

  pop()
end

--[[
  2016-06
  2017-09
  2018-02
  2018-05
  2024-03
]]
]=],
  ['workshop.concepts.Image.Color.Denormalize'] = [=[
-- Map normalized color components to byte range

-- Last mod.: 2024-11-25

-- Imports:
local MapTo = request('MapTo')
local ToInt = math.floor
local ApplyFunc = request('!.concepts.List.ApplyFunc')

local Denormalize =
  function(Color)
    local DestRange = { 0, 255 }
    local SourceRange = { 0.0, 1.0 }

    MapTo(DestRange, Color, SourceRange)

    return ApplyFunc(ToInt, Color)
  end

-- Exports:
return Denormalize

--[[
  2024-11-24
]]
]=],
  ['workshop.concepts.Image.Color.Interface'] = [=[
-- Color structure for images

--[[
  Color is a list of color components.

  Color component is float in [0.0, 1.0].
]]

-- Last mod.: 2024-11-25

-- Imports:
local NameList = request('!.concepts.List.AddNames')

local Color = { 0.0, 0.0, 0.0 }

local Names = { 'Red', 'Green', 'Blue' }

NameList(Color, Names)

-- Exports:
return Color

--[[
  2024-11-24
  2024-11-25
]]
]=],
  ['workshop.concepts.Image.Color.MapTo'] = [=[
-- Map color components to given range

-- Last mod.: 2024-11-25

-- Imports:
local MapToRange = request('!.number.map_to_range')
local ApplyFunc = request('!.concepts.List.ApplyFunc')

local MapTo =
  function(DestRange, Color, SrcRange)
    local CurrentMapToRange =
      function(ColorComponent)
        return MapToRange(DestRange, ColorComponent, SrcRange)
      end

    return ApplyFunc(CurrentMapToRange, Color)
  end

-- Exports:
return MapTo

--[[
  2024-11-24
]]
]=],
  ['workshop.concepts.Image.Color.Normalize'] = [=[
-- Normalize image color components that are in byte range [0, 255]

-- Last mod.: 2024-11-25

-- Imports:
local MapTo = request('MapTo')

local Normalize =
  function(Color)
    local DestRange = { 0.0, 1.0 }
    local SourceRange = { 0, 255 }

    return MapTo(DestRange, Color, SourceRange)
  end

-- Exports:
return Normalize

--[[
  2024-11-24
]]
]=],
  ['workshop.concepts.List.AddNames'] = [=[
-- Add names to list entries

-- Last mod.: 2024-11-25

-- Imports:
local InvertTable = request('!.table.invert')

--[[
  Name list entries by attaching metatable to list

  Example:

    local Color = { 128, 0, 255 }
    local ColorNames = { 'Red', 'Green', 'Blue' }
    NameList(Color, ColorNames)
    assert(Color.Red == Color[1])
]]
local NameList =
  function(List, Names)
    local NamesKeys = InvertTable(Names)

    local Metatable = {}

    Metatable.__index =
      function(Table, Key)
        return rawget(Table, NamesKeys[Key])
      end

    Metatable.__newindex =
      function(Table, Key, Value)
        if NamesKeys[Key] then
          rawset(Table, NamesKeys[Key], Value)
          return
        end
        rawset(Table, Key, Value)
      end

    setmetatable(List, Metatable)
  end

-- Exports:
return NameList

--[[
  2024-11-23
  2024-11-24
]]
]=],
  ['workshop.concepts.List.ApplyFunc'] = [=[
-- Modify list by applying function to each element. Returns list

--[[
  Here we're breaking functional paradigm "result of function is new
  value". We're modifying argument. It's practical.
]]

-- Last mod.: 2024-11-25

-- Exports:
return
  function(Func, List)
    assert_function(Func)
    assert_table(List)

    for Index = 1, #List do
      List[Index] = Func(List[Index])
    end

    return List
  end

--[[
  2024-11-24
]]
]=],
  ['workshop.concepts.List.ToString'] = [=[
-- Concatenate list of string values to string

-- Last mod.: 2024-10-20

return
  function(List, Separator)
    Separator = Separator or ''

    -- Meh, in Lua it's simple
    return table.concat(List, Separator)
  end

--[[
  2024-10-20
  2024-10-24
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.CompilePixel'] = [=[
-- Compile pixel to string

-- Last mod.: 2024-11-03

-- Exports:
return
  function(self, PixelIs)
    return
      string.format(
        self.PixelFmt,
        PixelIs[1],
        PixelIs[2],
        PixelIs[3]
      )
  end

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.Interface'] = [=[
-- Serialize to pixmap format

-- Last mod.: 2024-11-25

-- Exports:
return
  {
    -- Setup: Output stream
    Output = request('!.concepts.StreamIo.Output'),

    -- Main: Serialize anonymous structure to pixmap
    Run = request('Run'),

    -- [Config]

    -- Format label format (lol)
    LabelFmt = '%s  # Plain portable pixmap',

    -- Header serialization format
    HeaderFmt = '%s %s %s  # Width, Height, Max color component value',

    -- Lines (rows) separator
    LinesDelimiter = '',

    -- Columns (pixels) separator
    ColumnsDelimiter = '  ',

    -- Number of serialized pixels per line of output
    NumColumns = 4,

    -- Pixel serialization format
    PixelFmt = '%3s %3s %3s',

    -- [Internal]

    -- .ppm format constants
    Constants = request('^.Constants.Interface'),

    -- Write label
    WriteLabel = request('WriteLabel'),

    -- Write header
    WriteHeader = request('WriteHeader'),

    -- Write data
    WriteData = request('WriteData'),

    -- Compile pixel to string
    CompilePixel = request('CompilePixel'),

    -- Write string as line to output
    WriteLine = request('WriteLine'),
  }

--[[
  2024-11-02
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.Run'] = [=[
-- Convert from .is to .ppm

-- Last mod.: 2024-11-25

--[[
  Gets list of strings/lists structure. Writes in .ppm format.

  When failed returns false.
]]
local SerializePpm =
  function(self, PpmIs)
    local Label = self.Constants.FormatLabel
    local HeaderIs = PpmIs[1]
    local DataIs = PpmIs[2]

    self:WriteLabel(Label)
    self:WriteHeader(HeaderIs)
    self:WriteData(DataIs)

    return true
  end

-- Exports:
return SerializePpm

--[[
  2024-11-02
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.WriteData'] = [=[
-- Write pixels to output. We're doing some formatting

-- Last mod.: 2024-11-06

-- Imports:
local ListToString = request('!.concepts.List.ToString')

-- Exports:
return
  function(self, DataIs)
    local Height = #DataIs
    local Width = #DataIs[1]

    local ChunkSize = self.NumColumns
    local ColumnsDelim = self.ColumnsDelimiter
    local LinesDelim = self.LinesDelimiter

    self:WriteLine(LinesDelim)

    for Row = 1, Height do
      local Chunks = {}

      for Column = 1, Width do
        local PixelIs = DataIs[Row][Column]
        local PixelStr = self:CompilePixel(PixelIs)

        table.insert(Chunks, PixelStr)

        if (Column % ChunkSize == 0) then
          local ChunksStr = ListToString(Chunks, ColumnsDelim)
          Chunks = {}

          self:WriteLine(ChunksStr)
        end
      end

      -- Write remained chunk
      if (Width % ChunkSize ~= 0) then
        local ChunksStr = ListToString(Chunks, ColumnsDelim)
        self:WriteLine(ChunksStr)
      end

      self:WriteLine(LinesDelim)
    end
  end

--[[
  2024-11-02
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.WriteHeader'] = [=[
-- Write header to output

-- Last mod.: 2024-11-03

-- Exports
return
  function(self, HeaderIs)
    self:WriteLine(
      string.format(
        self.HeaderFmt,
        HeaderIs[1],
        HeaderIs[2],
        HeaderIs[3]
      )
    )
  end

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.WriteLabel'] = [=[
-- Write label string to output

-- Last mod.: 2024-11-02

-- Exports:
return
  function(self, Label)
    self:WriteLine(
      string.format(self.LabelFmt, Label)
    )
  end

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.WriteLine'] = [=[
-- Write string as line to output

-- Last mod.: 2024-11-02

-- Exports:
return
  function(self, String)
    self.Output:Write(String)
    self.Output:Write('\n')
  end

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.CompileColor'] = [=[
-- Anonymize color to list

-- Last mod.: 2024-11-25

-- Imports:
local DenormalizeColor = request('!.concepts.Image.Color.Denormalize')

-- Exports:
return
  function(self, Color)
    DenormalizeColor(Color)

    local RedIs = self:CompileColorComponent(Color.Red)
    local GreenIs = self:CompileColorComponent(Color.Green)
    local BlueIs = self:CompileColorComponent(Color.Blue)

    if not (RedIs and GreenIs and BlueIs) then
      return
    end

    return { RedIs, GreenIs, BlueIs }
  end

--[[
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.CompileColorComponent'] = [=[
-- Serialize color component integer

-- Last mod.: 2024-11-04

-- Imports:
local NumberInRange = request('!.number.in_range')

-- Exports:
return
  function(self, ColorComponent)
    local MaxColorValue = self.Constants.MaxColorValue
    local FormatStr = self.ColorComponentFmt

    if not is_integer(ColorComponent) then
      return
    end

    if not NumberInRange(ColorComponent, 0, MaxColorValue) then
      return
    end

    return string.format(FormatStr, ColorComponent)
  end

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.CompileHeader'] = [=[
-- Emit header anonymous structure

-- Last mod.: 2024-11-25

-- Exports:
return
  function(self, Image)
    local ImageHeight = #Image

    local ImageWidth = 0
    if Image[1] then
      ImageWidth = #Image[1]
    end

    local WidthIs = string.format(self.DimensionFmt, ImageWidth)

    local HeightIs = string.format(self.DimensionFmt, ImageHeight)

    local MaxValueIs =
      string.format(self.ColorComponentFmt, self.Constants.MaxColorValue)

    return { WidthIs, HeightIs, MaxValueIs }
  end

--[[
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.CompileImage'] = [=[
-- Compile pixels to anonymous structure

-- Last mod.: 2024-11-25

-- Exports:
return
  function(self, Image)
    local MatrixIs = {}

    for RowIndex, Row in ipairs(Image) do
      MatrixIs[RowIndex] = {}

      for ColumnIndex, Color in ipairs(Row) do
        if not Color then
          return
        end

        local ValueIs = self:CompileColor(Color)

        if not ValueIs then
          return
        end

        MatrixIs[RowIndex][ColumnIndex] = ValueIs
      end
    end

    return MatrixIs
  end

--[[
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.Interface'] = [=[
-- Compile named Lua table to anonymous structure (list of strings/lists)

-- Last mod.: 2024-11-25

-- Exports:
return
  {
    -- Main: Convert table with .ppm to anonymous tree
    Run = request('Run'),

    -- [Config]

    -- Dimension (width and height) serialization format
    DimensionFmt = '%d',

    -- Color component serialization format
    ColorComponentFmt = '%03d',

    -- [Internal]

    -- Format constants
    Constants = request('^.Constants.Interface'),

    -- Compile header
    CompileHeader = request('CompileHeader'),

    -- Compile image data
    CompileImage = request('CompileImage'),

    -- Compile color
    CompileColor = request('CompileColor'),

    -- Serialize color component
    CompileColorComponent = request('CompileColorComponent'),
  }

--[[
  2024-11-03
  2024-11-04
  2024-11-06
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.Run'] = [=[
-- Anonymize parsed .ppm

-- Last mod.: 2024-11-25

--[[
  Compile Lua table to anonymous structure
]]
local Compile =
  function(self, Image)
    local HeaderIs = self:CompileHeader(Image)
    local DataIs = self:CompileImage(Image)

    if not (HeaderIs and DataIs) then
      return
    end

    return { HeaderIs, DataIs }
  end

-- Exports:
return Compile

--[[
  2024-11-03
  2024-11-06
]]
]=],
  ['workshop.concepts.Ppm.Constants.Interface'] = [=[
-- Format constants

-- Last mod.: 2024-11-02

-- Exports:
return
  {
    -- Format label
    FormatLabel = 'P3',

    --[[
       Max color component value

       Despite that format allows any integer in [1, 65535]
       we're fixing it to constant.

       Color component value should be between 0 and this number.
    ]]
    MaxColorValue = 255,

    -- Check that given string is our format label
    IsValidLabel = request('IsValidLabel'),
  }

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Constants.IsValidLabel'] = [=[
-- Check that given string is our format label

-- Last mod.: 2024-11-02

-- Exports:
return
  function(self, Label)
    return (Label == self.FormatLabel)
  end

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Interface'] = [=[
-- Encode/decode .ppm file to Lua table

-- Last mod.: 2024-11-06

-- Exports:
return
  {
    -- [Config]

    -- Input stream
    Input = request('!.concepts.StreamIo.Input'),

    -- Output stream
    Output = request('!.concepts.StreamIo.Output'),

    -- [Main]

    -- Load image from stream
    Load = request('Load'),

    -- Save image to stream
    Save = request('Save'),
  }

--[[
  2024-11-04
]]
]=],
  ['workshop.concepts.Ppm.Load'] = [=[
-- Load image from stream

-- Last mod.: 2024-11-23

-- Imports:
local Parser_PpmToIs = request('Parser_PpmToIs.Interface')
local Parser_IsToLua = request('Parser_IsToLua.Interface')

-- Exports:
return
  function(self)
    Parser_PpmToIs.Input = self.Input

    local ImageIs = Parser_PpmToIs:Run()

    if not ImageIs then
      return
    end

    local Image = Parser_IsToLua:Run(ImageIs)

    if not Image then
      return
    end

    return Image
  end

--[[
  2024-11-04
]]
]=],
  ['workshop.concepts.Ppm.Parser_IsToLua.Interface'] = [=[
-- Parse from anonymous structure to custom Lua format

-- Last mod.: 2024-11-25

-- Exports:
return
  {
    -- [Main] Parse pixmap structure to Lua table in custom format
    Run = request('Run'),

    -- [Internal]

    -- .ppm format constants
    Constants = request('^.Constants.Interface'),

    -- Parse raw pixels data
    ParsePixels = request('ParsePixels'),

    -- Parse pixel
    ParsePixel = request('ParsePixel'),

    -- Parse color component value
    ParseColorComponent = request('ParseColorComponent'),
  }

--[[
  2024-11-02
  2024-11-06
]]
]=],
  ['workshop.concepts.Ppm.Parser_IsToLua.ParseColorComponent'] = [=[
-- Parse color component value

-- Last mod.: 2024-11-06

-- Imports:
local NumberInRange = request('!.number.in_range')

--[[
  Parse color component value from string to integer.

  Checks that integer is within max color component range.

  In case of problems returns nil.
]]
local ParseColorComponent =
  function(self, Value)
    local MaxColorValue = self.Constants.MaxColorValue

    Value = tonumber(Value)

    if not is_integer(Value) then
      return
    end

    if not NumberInRange(Value, 0, MaxColorValue) then
      return
    end

    return Value
  end

-- Exports:
return ParseColorComponent

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Parser_IsToLua.ParsePixel'] = [==[
-- Parse raw pixel data

-- Last mod.: 2024-11-25

-- Imports:
local BaseColor = request('!.concepts.Image.Color.Interface')
local NormalizeColor = request('!.concepts.Image.Color.Normalize')

--[=[
  Parses raw pixel data to annotated list

  { '0', '128', '255' } -> { 0, 128, 255 --[[ aka .Red, .Green, .Blue ]] }

  In case of problems returns nil.
]=]
local ParsePixel =
  function(self, PixelIs)
    local Red = self:ParseColorComponent(PixelIs[1])
    local Green = self:ParseColorComponent(PixelIs[2])
    local Blue = self:ParseColorComponent(PixelIs[3])

    if not (Red and Green and Blue) then
      return
    end

    local Color = new(BaseColor, { Red, Green, Blue })
    NormalizeColor(Color)

    return Color
  end

-- Exports:
return ParsePixel

--[[
  2024-11-03
  2024-11-25
]]
]==],
  ['workshop.concepts.Ppm.Parser_IsToLua.ParsePixels'] = [==[
-- Parse raw pixels data

-- Last mod.: 2024-11-25

--[=[
  Parse raw pixels data.

  { { { '0', '128', '255' } } } ->

  { { { 0, 128, 255 --[[ aka .Red, .Green, .Blue ]] } } }
]=]
local ParsePixels =
  function(self, DataIs)
    local Matrix = {}

    for RowIndex, Row in ipairs(DataIs) do
      Matrix[RowIndex] = {}

      for ColumnIndex, PixelIs in ipairs(Row) do
        local Pixel = self:ParsePixel(PixelIs)

        if not Pixel then
          return
        end

        Matrix[RowIndex][ColumnIndex] = Pixel
      end
    end

    return Matrix
  end

-- Exports:
return ParsePixels

--[[
  2024-11-03
  2024-11-25
]]
]==],
  ['workshop.concepts.Ppm.Parser_IsToLua.Run'] = [=[
-- Gets structure as grouped strings. Returns table with nice names

-- Last mod.: 2024-11-25

--[[
  Custom Lua format

  Input

    1x2 bitmap

    {
      { '1', '2', '255' },
      {
        { { '0', '128', '255' } },
        { { '128', '255', '0' } },
      }
    }

  is converted to

    {
      { { 0, 128, 255 } },
      { { 128, 255, 0 } },
    }

  On fail it returns nil.

  Some fail conditions:

    * Holes at Input[2] data matrix.
    * If there is color component value that is not in range [0, 255]
]]

-- Exports:
return
  function(self, DataIs)
    local PixelsIs = DataIs[2]

    local Pixels = self:ParsePixels(PixelsIs)

    if not Pixels then
      return
    end

    return Pixels
  end

--[[
  2024-11-02
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.GetChunk'] = [=[
-- Load given amount of items

-- Last mod.: 2024-11-03

--[[
  Get specified amount of items from input stream.

  Return list of items. If failed, return nil.
]]
local GetChunk =
  function(self, NumItems)
    local Result = {}

    for i = 1, NumItems do
      local Item = self:GetNextItem()

      if not Item then
        return
      end

      table.insert(Result, Item)
    end

    return Result
  end

-- Exports:
return GetChunk

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.GetNextCharacter'] = [=[
-- Get next character

-- Last mod.: 2024-11-02

--[[
  Get next character from input stream.

  We store character in <.NextCharacter>.

  On end of stream:

    <.NextCharacter> = nil
    return false

  We can't move stream back. So parsers should call this method
  only when they are done with current <.NextCharacter>.
]]
local GetNextCharacter =
  function(self)
    local Char, IsOkay = self.Input:Read(1)

    if not IsOkay then
      self.NextCharacter = nil

      return false
    end

    self.NextCharacter = Char

    return true
  end

-- Exports:
return GetNextCharacter

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.GetNextItem'] = [=[
-- Get next item

-- Last mod.: 2024-11-04

local IsSpace =
  function(Char)
    return
      (Char == ' ') or
      (Char == '\t')
  end

local IsNewline =
  function(Char)
    return
      (Char == '\n') or
      (Char == '\r')
  end

local IsDelimiter =
  function(Char)
    return IsSpace(Char) or IsNewline(Char)
  end

-- Read until end of stream or until end of line
local SkipLine =
  function(self)
    while self:GetNextCharacter() do
      if IsNewline(self.NextCharacter) then
        break
      end
    end
  end

--[[
  Get next item

  Skips line comments.

    > P3
    > 1920 1080 # Width Height
    > 255

  Items are "P3", "1920", "1080", "255"
]]
local GetNextItem =
  function(self)
    local Char

    ::Redo::

    -- Space eating cycle
    while self:GetNextCharacter() do
      Char = self.NextCharacter

      if not IsDelimiter(Char) then
        break
      end

      PrevChar = Char
    end

    -- Check for line comment
    do
      local CommentChar = '#'

      if (Char == CommentChar) then
        -- Skip until end of line. Damned comment
        SkipLine(self)
        goto Redo
      end
    end

    -- Catenate characters to <Term>
    local Term = Char

    while self:GetNextCharacter() do
      Char = self.NextCharacter

      if IsDelimiter(Char) then
        break
      end

      Term = Term .. Char
    end

    return Term
  end

-- Exports:
return GetNextItem

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.GetPixels'] = [=[
-- Load raw pixels data from .ppm stream

-- Last mod.: 2024-11-03

--[[
  Load pixels data from .ppm stream

  Requires parsed header to know dimensions of data.
  Data values are not processed. But grouped.

  In case there are not enough data, return nil.
  Else return matrix of (height x width x 3).
]]
local GetPixels =
  function(self, Header)
    local Data = {}

    for Row = 1, Header.Height do
      local RowData = {}

      for Column = 1, Header.Width do
        local NumColorComponents = 3
        local Color = self:GetChunk(NumColorComponents)

        if not Color then
          return
        end

        RowData[Column] = Color
      end

      Data[Row] = RowData
    end

    return Data
  end

-- Exports:
return GetPixels

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.Interface'] = [=[
-- Load pixmap to itness format (list with strings and lists)

-- Last mod.: 2024-11-06

-- Exports:
return
  {
    -- [Config]

    -- Input stream
    Input = request('!.concepts.StreamIo.Input'),

    -- [Main] Load pixmap to itness format
    Run = request('Run'),

    -- [Internal]

    -- .ppm format constants
    Constants = request('^.Constants.Interface'),

    -- Next character. Used by GetNextCharacter()
    NextCharacter = nil,

    -- Get next character
    GetNextCharacter = request('GetNextCharacter'),

    -- Get next item
    GetNextItem = request('GetNextItem'),

    -- Get chunk of items
    GetChunk = request('GetChunk'),

    -- Parse header from raw data
    ParseHeader = request('ParseHeader'),

    -- Load raw pixels data from input stream
    GetPixels = request('GetPixels'),
  }

--[[
  2024-11-02
  2024-11-03
  2024-11-06
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.ParseHeader'] = [=[
-- Parse header from list to table

-- Last mod.: 2024-11-25

-- Imports:
local IsNaturalNumber = request('!.number.is_natural')

--[[
  Parse header in Itness format to Lua table

  Example:

    { '60', '30', '255' } -> { Width = 60, Height = 30 }
]]
local ParseHeader =
  function(self, HeaderIs)
    local WidthIs = HeaderIs[1]
    local HeightIs = HeaderIs[2]

    local Width = tonumber(WidthIs)
    assert(IsNaturalNumber(Width))

    local Height = tonumber(HeightIs)
    assert(IsNaturalNumber(Height))

    return { Width = Width, Height = Height }
  end

-- Exports:
return ParseHeader

--[[
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.Run'] = [=[
-- Read in .ppm format. Return structure in itness format (grouped strings)

-- Last mod.: 2024-11-06

--[[
  Normally it returns Lua list with strings and lists.

  On fail it returns nil.

  Fail conditions:

    * There are less values than required for (width x height x 3)
      matrix

  .ppm format allows line comments "# blah blah\n". They are lost.

  Example

    .ppm

      > P3 1 2 255 0 128 255 128 255 0

    is loaded as

      {
        { '1', '2', '255' },
        {
          { { '0', '128', '255' } },
          { { '128', '255', '0' } },
        }
      }
]]

--[[
  Convert from pixmap to itness

  Returns nil if problems.
]]
local Parse =
  function(self)
    local Label = self:GetNextItem()

    if not self.Constants:IsValidLabel(Label) then
      return
    end

    local NumItemsInHeader = 3
    local HeaderIs = self:GetChunk(NumItemsInHeader)

    if not HeaderIs then
      return
    end

    local Header = self:ParseHeader(HeaderIs)

    if not Header then
      return
    end

    local PixelsIs = self:GetPixels(Header)

    if not PixelsIs then
      return
    end

    return { HeaderIs, PixelsIs }
  end

-- Exports:
return Parse

--[[
  2024-11-02
  2024-11-03
  2024-11-05
]]
]=],
  ['workshop.concepts.Ppm.Save'] = [=[
-- Save image to stream

-- Last mod.: 2024-11-23

-- Imports:
local Compiler_LuaToIs = request('Compiler_LuaToIs.Interface')
local Compiler_IsToPpm = request('Compiler_IsToPpm.Interface')

-- Exports:
return
  function(self, Image)
    local ImageIs = Compiler_LuaToIs:Run(Image)

    if not ImageIs then
      return
    end

    Compiler_IsToPpm.Output = self.Output

    local IsOkay = Compiler_IsToPpm:Run(ImageIs)

    if not IsOkay then
      return
    end

    return true
  end

--[[
  2024-11-04
]]
]=],
  ['workshop.concepts.StreamIo.Input'] = [=[
-- Reader interface

--[[
  Exports

    {
      Read() - read function
    }
]]

--[[
  Read given amount of bytes to string

  Input:
    NumBytes (uint) >= 0

  Output:
    Data (string)
    IsComplete (bool)

  Details

    If we can't read <NumBytes> bytes we read what we can and set
    <IsComplete> to FALSE. Typical case is empty string for end-of-file
    state.

    Reading zero bytes is neutral operation which can be used to detect
    problems through <IsComplete> flag.
]]
local Read =
  function(self, NumBytes)
    assert_integer(NumBytes)
    assert(NumBytes >= 0)

    local ResultStr = ''
    local IsComplete = false

    return ResultStr, IsComplete
  end

-- Exports:
return
  {
    Read = Read,
  }

--[[
  2024-07-19
  2024-07-24
]]
]=],
  ['workshop.concepts.StreamIo.Input.File'] = [=[
-- Reads strings from file. Implements [Input]

-- Last mod.: 2024-11-11

local OpenForReading = request('!.file_system.file.OpenForReading')
local CloseFileFunc = request('!.file_system.file.Close')

-- Contract: Read string from file
local Read =
  function(self, NumBytes)
    assert_integer(NumBytes)
    assert(NumBytes >= 0)

    local Data = ''
    local IsComplete = false

    Data = self.FileHandle:read(NumBytes)

    local IsEof = is_nil(Data)

    -- No End-of-File state in [Input]
    if IsEof then
      Data = ''
    end

    IsComplete = (#Data == NumBytes)

    return Data, IsComplete
  end

-- Intestines: Open file for reading
local OpenFile =
  function(self, FileName)
    local FileHandle = OpenForReading(FileName)

    if is_nil(FileHandle) then
      return false
    end

    self.FileHandle = FileHandle

    return true
  end

-- Intestines: close file
local CloseFile =
  function(self)
    return (CloseFileFunc(self.FileHandle) == true)
  end

local Interface =
  {
    -- [New]

    -- Open file by name
    Open = OpenFile,

    -- Close file
    Close = CloseFile,

    -- [Main]: Read bytes
    Read = Read,

    -- Intestines
    FileHandle = 0,
  }

-- Close file at garbage collection
setmetatable(Interface, { __gc = function(self) self:Close() end } )

-- Exports:
return Interface

--[[
  2024-07-19
  2024-07-24
  2024-08-05
  2024-08-09
  2024-11-11
]]
]=],
  ['workshop.concepts.StreamIo.Output'] = [=[
-- Writer interface

--[[
  Exports:

    {
      Write() - write function
    }
]]

--[[
  Write string

  Input:
    Data (string)

  Output:
    NumBytesWritten (uint)
    IsCompleted (bool)

  Details

    Writing empty string is neutral operation which can be used to
    detect problems by examining <IsCompleted> flag.
]]
local Write =
  function(self, Data)
    assert_string(Data)

    local NumBytesWritten = 0
    local IsCompleted = false

    return NumBytesWritten, IsCompleted
  end

-- Exports:
return
  {
    Write = Write,
  }

--[[
  2024-07-19
  2024-07-24
]]
]=],
  ['workshop.concepts.StreamIo.Output.File'] = [=[
-- Writes strings to file. Implements [Output]

-- Last mod.: 2024-11-11

local OpenForWriting = request('!.file_system.file.OpenForWriting')
local CloseFileFunc = request('!.file_system.file.Close')

-- Contract: Write string to file
local Write =
  function(self, Data)
    assert_string(Data)

    local IsOk = self.FileHandle:write(Data)

    if is_nil(IsOk) then
      return 0, false
    end

    return #Data, true
  end

-- Intestines: Open file for writing
local OpenFile =
  function(self, FileName)
    local FileHandle = OpenForWriting(FileName)

    if is_nil(FileHandle) then
      return false
    end

    self.FileHandle = FileHandle

    return true
  end

-- Intestines: close file
local CloseFile =
  function(self)
    return (CloseFileFunc(self.FileHandle) == true)
  end

local Interface =
  {
    -- [Added]

    -- Open file by name
    Open = OpenFile,

    -- Close file
    Close = CloseFile,

    -- [Main]: Write string
    Write = Write,

    -- [Internals]
    FileHandle = 0,
  }

-- Close file at garbage collection
setmetatable(Interface, { __gc = function(self) self:Close() end } )

-- Exports:
return Interface

--[[
  2024-07-19
  2024-07-24
  2024-08-05
  2024-08-09
  2024-11-11
]]
]=],
  ['workshop.file_system.file.Close'] = [=[
-- Close file object

--[[
  Stock Lua explodes with exception on double close.
  I want idempotence.
]]

--[[
  Close file object

  Input
    file

  Output
    nil(if not applicable) or bool(file is closed)

  Notes
    Lua's "io" do not closes stdins etc. We reflect this in boolean
    result. For most practical cases is can be ignored.
]]
return
  function(File)
    local IsFile = is_string(io.type(File))

    if not IsFile then
      return
    end

    local IsClosed = (io.type(File) == 'closed file')
    if IsClosed then
      return true
    end

    local IsOk = io.close(File)

    return IsOk
  end

--[[
  2024-08-09
]]
]=],
  ['workshop.file_system.file.OpenForReading'] = [=[
-- Open file for reading

return
  function(FileName)
    assert_string(FileName)

    local File = io.open(FileName, 'rb')

    if is_nil(File) then
      return
    end

    return File
  end

--[[
  2024-08-09
]]
]=],
  ['workshop.file_system.file.OpenForWriting'] = [=[
-- Open file for writing

return
  function(FileName)
    assert_string(FileName)

    local File = io.open(FileName, 'w+b')

    if is_nil(File) then
      return
    end

    return File
  end

--[[
  2024-08-09
]]
]=],
  ['workshop.lua.data_mathtypes'] = [=[
-- Return list of numeric type names

--[[
  Output

    table

      List with number type names as they are returned
      by math.type() function.

  Note

    Used in code generation.
]]

-- Last mod.: 2024-08-06

return
  {
    'integer',
    'float',
  }

--[[
  2024-03-02
]]
]=],
  ['workshop.lua.data_types'] = [=[
-- Return list with names of all Lua data types

--[[
  Output

    table

      List of strings with type names as they are returned
      by type() function.

  Note

    Used in code generation.
]]

-- Last mod.: 2024-08-06

return
  {
    'nil',
    'boolean',
    'number',
    'string',
    'function',
    'thread',
    'userdata',
    'table',
  }

--[[
  2018-02
]]
]=],
  ['workshop.number.constrain'] = [=[
-- Constrain given number between min and max values

-- Last mod.: 2024-11-24

return
  function(num, min, max)
    if (num < min) then
      return min
    end

    if (num > max) then
      return max
    end

    return num
  end

--[[
  2020-09
]]
]=],
  ['workshop.number.fit_to_range'] = [=[
-- Fit number into given range

-- Last mod.: 2024-11-24

--[[
  Basically it's classic constrain() (aka clamp()) but here
  we're passing range as list, not as two arguments.
]]

-- Imports:
local Clamp = request('!.number.constrain')

--[[
  Fit number to given range

  Input
    Number
    Range
      [1] - min
      [2] - max
  Output
    number
]]
local FitToRange =
  function(Number, Range)
    return Clamp(Number, Range[1], Range[2])
  end

-- Exports:
return FitToRange

--[[
  2024-11-24
]]
]=],
  ['workshop.number.in_range'] = [=[
--[[
  Return true if given number in specified range.
]]

return
  function(num, min, max)
    return (num >= min) and (num <= max)
  end
]=],
  ['workshop.number.is_natural'] = [=[
-- Return true if argument is natural number

--[[
  Natural numbers sequence starts as 1, 2, 3, ...
  Note that we do not include 0.
  This sequence is also called "counting numbers".

  Zero is neutral element to addition. It's great as
  initialization value. In multiplication using zero creates
  more problems than it solves.
]]

-- Last mod.: 2024-11-03

return
  function(Number)
    assert_number(Number)

    if not is_integer(Number) then
      return false
    end

    if (Number <= 0) then
      return false
    end

    return true
  end

--[[
  2024-11-03
]]
]=],
  ['workshop.number.map_to_range'] = [=[
-- Map number belonging to one range to number in another range

-- Last mod.: 2024-11-24

-- Imports:
local FitToRange = request('!.number.fit_to_range')

--[[
  Parameters order may look strange here. But consider
  calling it with infix notation: {0.0, 1.0}.MapNumber(64, {0, 255})
]]
local MapNumber =
  function(DestRange, Number, SrcRange)
    --[[
      Typical implementation is usually uses one formula.
      I can understand it and write it that way.
      But I value clarity more than smartassism and some performance.
    ]]

    local SrcRangeLen = SrcRange[2] - SrcRange[1]
    local DestRangeLen = DestRange[2] - DestRange[1]

    Number = FitToRange(Number, SrcRange)

    -- Offset in source range
    Number = Number - SrcRange[1]
    -- Part of source range
    Number = Number / SrcRangeLen
    -- Offset in dest range
    Number = Number * DestRangeLen
    -- Value in dest range
    Number = Number + DestRange[1]

    return Number
  end

-- Exports:
return MapNumber

--[[
  2024-11-24
]]
]=],
  ['workshop.system.install_assert_functions'] = [=[
-- Function to spawn "assert_<type>" family of global functions

local data_types = request('!.lua.data_types')
local data_mathtypes = request('!.lua.data_mathtypes')

local generic_assert =
  function(type_name)
    -- assert_string(type_name)
    assert(type(type_name) == 'string')

    local checker_name = 'is_'.. type_name
    local checker = _G[checker_name]

    -- assert_function(checker)
    assert(type(checker) == 'function')

    return
      function(val)
        if not checker(val) then
          local err_msg =
            string.format('assert_%s(%s)', type_name, tostring(val))
          error(err_msg)
        end
      end
  end

return
  function()
    for _, type_name in ipairs(data_types) do
      local global_name = 'assert_' .. type_name
      _G[global_name] = generic_assert(type_name)
    end

    for _, number_type_name in ipairs(data_mathtypes) do
      local global_name = 'assert_' .. number_type_name
      _G[global_name] = generic_assert(number_type_name)
    end
  end

--[[
  2018-02
  2020-01
  2022-01
  2024-03
]]
]=],
  ['workshop.system.install_is_functions'] = [=[
-- Function to spawn "is_<type>" family of global functions.

--[[
  It spawns "is_nil", "is_boolean", ... for all Lua data types.
  Also it spawns "is_integer" and "is_float" for number type.
]]

--[[
  Design

    f(:any) -> bool

    Original design was

      f(:any) -> bool, (string or nil)

      Use case was "assert(is_number(x))" which will automatically
      provide error message when "x" is not a number.

      Today I prefer less fancy designs. Caller has enough information
      to build error message itself.
]]

-- Last mod.: 2024-03-02

local data_types = request('!.lua.data_types')
local data_mathtypes = request('!.lua.data_mathtypes')

local type_is =
  function(type_name)
    return
      function(val)
        return (type(val) == type_name)
      end
  end

local number_is =
  function(type_name)
    return
      function(val)
        --[[
          math.type() throws error for non-number types.
          This function returns "false" for non-number types.
        ]]
        if not is_number(val) then
          return false
        end
        return (math.type(val) == type_name)
      end
  end

return
  function()
    for _, type_name in ipairs(data_types) do
      _G['is_' .. type_name] = type_is(type_name)
    end
    for _, math_type_name in ipairs(data_mathtypes) do
      _G['is_' .. math_type_name] = number_is(math_type_name)
    end
  end

--[[
  2018-02
  2020-01
  2022-01
  2024-03 Changed design
]]
]=],
  ['workshop.table.clone'] = [=[
local cloned = {}

local clone
clone =
  function(node)
    if (type(node) == 'table') then
      if cloned[node] then
        return cloned[node]
      else
        local result = {}
        cloned[node] = result
        for k, v in pairs(node) do
          result[clone(k)] = clone(v)
        end
        setmetatable(result, getmetatable(node))
        return result
      end
    else
      return node
    end
  end

return
  function(node)
    cloned = {}
    return clone(node)
  end

--[[
* Metatables are shared, not cloned.

* This code optimized for performance.

  Main effect gave changing "is_table" to explicit type() check.
]]
]=],
  ['workshop.table.invert'] = [[
return
  function(t)
    assert_table(t)
    local result = {}
    for k, v in pairs(t) do
      result[v] = k
    end
    return result
  end
]],
  ['workshop.table.new'] = [=[
--[[
  Clone table <base_obj>. Optionally override fields in clone with
  fields from <overriden_params>.

  Returns cloned table.
]]

local clone = request('clone')
local patch = request('patch')

return
  function(base_obj, overriden_params)
    assert_table(base_obj)
    local result = clone(base_obj)
    if is_table(overriden_params) then
      patch(result, overriden_params)
    end
    return result
  end
]=],
  ['workshop.table.patch'] = [=[
-- Apply patch to table

-- Last mod.: 2024-11-11

--[[
  Basically it means that we're writing every entity from patch table to
  destination table.

  If no key in destination table, we'll explode.

  Additional third parameter means that we're not overwriting
  entity in destination table if it's value type is same as
  in patch's entity.

  That's useful when we want to force values to given types but
  keep values if they have correct type:

    ({ x = 42, y = '?' }, { x = 0, y = 0 }, false) -> { x = 0, y = 0 }
    ({ x = 42, y = '?' }, { x = 0, y = 0 }, true) -> { x = 42, y = 0 }

  Examples:

    Always overwriting values:

      ({ a = 'A' }, { a = '_A' }, false) -> { a = '_A' }

    Overwriting values if different types:

      ({ a = 'A' }, { a = '_A' }, true) -> { a = 'A' }
      ({ a = 0 }, { a = '_A' }, true) -> { a = '_A' }

    Nested values are supported:

      ({ b = { bb = 'BB' } }, { b = { bb = '_BB' } }, false) ->
      { b = { bb = '_BB' } }
]]

local Patch
Patch =
  function(MainTable, PatchTable, IfDifferentTypesOnly)
    assert_table(MainTable)
    assert_table(PatchTable)

    for PatchKey, PatchValue in pairs(PatchTable) do
      local MainValue = MainTable[PatchKey]

      -- Missing key in destination
      if is_nil(MainValue) then
        local ErrorMsg =
          string.format(
            [[Destination table doesn't have key "%s".]],
            tostring(PatchKey)
          )

        error(ErrorMsg, 2)
      end

      local DoPatch = true

      if IfDifferentTypesOnly then
        MainValueType = type(MainValue)
        PatchValueType = type(PatchValue)
        DoPatch = (MainValueType ~= PatchValueType)
      end

      if DoPatch then
        -- Recursive call when we're writing table to table
        if is_table(MainValue) and is_table(PatchValue) then
          Patch(MainValue, PatchValue)
        -- Else just overwrite value
        else
          MainTable[PatchKey] = PatchValue
        end
      end
    end
  end

-- Exports:
return Patch

--[[
  2016-09
  2024-02
  2024-11
]]
]=],
}

local AddModule =
  function(Name, Code)
    local CompiledCode = assert(load(Code, Name, 't'))

    _G.package.preload[Name] =
      function(...)
        return CompiledCode(...)
      end
  end

for ModuleName, ModuleCode in pairs(Modules) do
  AddModule(ModuleName, ModuleCode)
end

require('workshop.base')
