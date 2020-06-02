local core = require "core"
local config = require "core.config"
local tokenizer = require "core.tokenizer"
local Object = require "core.object"


local Highlighter = Object:extend()


function Highlighter:new(doc)
  self.doc = doc
  self:reset()

  -- init incremental syntax highlighting
  core.add_thread(function()
    while true do
      if self.first_invalid_line > self.max_wanted_line then
        self.max_wanted_line = 0
        coroutine.yield(1 / config.fps)

      else
        local max = math.min(self.first_invalid_line + 40, self.max_wanted_line)

        for i = self.first_invalid_line, max do
          local state = (i > 1) and self.lines[i - 1].state
          local line = self.lines[i]
          if not (line and line.init_state == state) then
            self.lines[i] = self:tokenize_line(i, state)
          end
        end

        self.first_invalid_line = max + 1
        core.redraw = true
        coroutine.yield()
      end
    end
  end, self)
end


function Highlighter:reset()
  self.lines = {}
  self.first_invalid_line = 1
  self.max_wanted_line = 0
end


function Highlighter:invalidate(idx)
  self.first_invalid_line = math.min(self.first_invalid_line, idx)
  self.max_wanted_line = math.min(self.max_wanted_line, #self.doc.lines)
end


function Highlighter:tokenize_line(idx, state)
  local res = {}
  res.init_state = state
  res.text = self.doc.lines[idx]
  res.tokens, res.state = tokenizer.tokenize(self.doc.syntax, res.text, state)
  return res
end


function Highlighter:get_line(idx)
  local line = self.lines[idx]
  if not line or line.text ~= self.doc.lines[idx] then
    local prev = self.lines[idx - 1]
    line = self:tokenize_line(idx, prev and prev.state)
    self.lines[idx] = line
  end
  self.max_wanted_line = math.max(self.max_wanted_line, idx)
  return line
end


function Highlighter:each_token(idx)
  return tokenizer.each_token(self:get_line(idx).tokens)
end


return Highlighter
