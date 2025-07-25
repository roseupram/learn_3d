local modules = (...) and (...):gsub('%.init$', '') .. ".modules." or ""

---@class MathLib
---@field quat Quaternion
---@field vec3 Vector3
---@field utils ML_Utils
---@field bvh BVH 
---@field mat4 Matrix4
---@field bound3 Bound3
local ml = {
}

local files = {
      "utils",
      "vec2",
      "vec3",
      "vec4",
      "mat4",
      "quat",
      "bound3",
      "bvh",
      "intersect"
}

for _, file in ipairs(files) do
      ml[file] = require(modules .. file)
end

return ml