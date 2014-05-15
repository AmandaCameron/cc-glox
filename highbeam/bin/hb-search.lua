-- @Name: HighBeam Search
-- @Description: Searches the database for the given arguments.
-- @Author: Amanda Cameron

os.loadAPI("__LIB__/highbeam/highbeam")

local db = kidven.new("hb-connection")

local args = { ... }

local query = args[1]

local results = db:query(query)

if #results == 0 then
  print("No Results.")
end

for _, res in ipairs(results) do
  if res.meta.name then
    print(res.meta.name)
  else
    print(res.uri)
  end
end