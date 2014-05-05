-- Shows information for a given URI

local uri = ...

os.loadAPI("__LIB__/highbeam/highbeam")

local db = kidven.new("hb-database", kidven.new('hb-env'))

db:load()

for id, data in pairs(db.data) do
  if data.uri == uri then
    print("ID: " .. id)
    print("Meta Data:")
    for k, v in pairs(data.meta) do
      print(k .. ": " .. tostring(v))
    end

    return
  end
end

print("No Data Found.")