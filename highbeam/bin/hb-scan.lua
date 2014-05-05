-- Scans the HighBeam database..

local args = { ... }

os.loadAPI("__LIB__/highbeam/highbeam")

local db = kidven.new('hb-connection')

if not db.remote then
  print("Scanning...")
else
  print("Scheduling scan in backend.")
end

db:scan()

if args[1] == "--wait" and db.remote then
  print("Waiting for scan to complete.")
  
  while true do
    local _, cmd, arg = os.pullEvent("hb-ipc")

    if cmd == "status" then
      if state == "idle" then
        print("Done.")
        return
      end
    end
  end
end