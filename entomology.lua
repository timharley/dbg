local nc = require 'ncurses'

local ent = {}


local function atexit()
  print("~ent")
end

function ent.getsource(file, line)
    local source = io.open(string.sub(file, 2), 'r')
    local display = {}
    local i = 0
    if source then
        for l in source:lines() do
            i = i + 1
            --if (i + 5 > line) and (i - 5 < line) then
            if i == line then 
                table.insert(display, "> "..l)
            else
                table.insert(display, "| "..l)
            end
        end
    end
    if #display > 0 then
        return table.concat(display, '\n')
    else
        return "No source for "..file..":"..tostring(line)..'\n'
    end
end

setmetatable(ent, {__gc = atexit})
function ent.run(trace)
  while true do
      nc.initscr()
      local success, msg = xpcall(function() nc.printw("Hello world!\n")
          nc.printw(ent.getsource(trace.source, trace.currentline))
      end, debug.traceback)
      if not success then
        nc.printw("some error")
        nc.printw(msg..'\n')
      end
      nc.refresh()
      local char = nc.getch()
      nc.erase()
      nc.endwin()
      if char == 'q' then break end
      trace = coroutine.yield()
  end
end

function ent.hook()
    if not coroutine.status(ent.co) ~= "dead" then
        local success, value = coroutine.resume(ent.co, debug.getinfo(2, "Sl"))
        --local success, value = coroutine.resume(ent.co, debug.traceback("Hook:", 2))
    end
end

function ent.start(f)
    ent.co = coroutine.create(ent.run)
    return debug.sethook(ent.hook, "l")
end



return ent
