-- Minimal example of using Menori
--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

local menori = require 'menori'

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat

--class inherited from Scene.
---@class s: Scene
local scene = menori.Scene:extend('minimal_scene')

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local gltf = menori.glTFLoader.load('examples/assets/etrian_odyssey_3_monk.glb')
	local pig_plane_model = menori.glTFLoader.load('examples/assets/pigplane.glb')
	local pig_plane = menori.NodeTreeBuilder.create(pig_plane_model, function (scene, builder)
		-- Create BVH for each mesh node.
		scene:traverse(function (node)
			if node.mesh then
				node.bvh = ml.bvh(node.mesh, 10, node.world_matrix)
			end
		end)
	end)[1]
	-- pig_plane:set_scale(2,2,2)

	-- build a scene node tree from the gltf data and initialize the animations
	local scenes = menori.NodeTreeBuilder.create(gltf, function (scene, builder)
		self.animations = menori.glTFAnimations(builder.animations)
		self.animations:set_action(1)
	end)
	for i,v in ipairs{'player','enemy'} do
		local player = menori.glTFLoader.load('examples/assets/'..v..'.glb')
		local model = menori.NodeTreeBuilder.create(player)[1]
		model:set_position(i, 0, i)
		self.root_node:attach(model)
	end
	self.player = self.root_node.children[1]
	self.ground = pig_plane
	-- adding scene to the root node.
	self.root_node:attach(scenes[1])
	self.root_node:attach(pig_plane)
	self.y_angle = 0
	self.time=0
	self.eye_distance=4
	self.x_angle = math.rad(-30)
end

function scene:render()
	love.graphics.clear(0.3, 0.25, 0.2)
	-- recursively draw the scene nodes
	self:render_nodes(self.root_node, self.environment, {
		node_sort_comp = menori.Scene.alpha_mode_comp
	})
end

function scene:update(dt)
	local mx, my = love.mouse.getPosition()
	local ray = self.camera:screen_point_to_ray(mx, my)
	local intersect_list = {}
	self.ground:traverse(function (node)
		if node.bvh then
			local t = node.bvh:intersect_ray(ray)
			if #t > 0 then
				table.insert(intersect_list, t[1])
			end
		end
	end)

	-- Sorted by distance.
	table.sort(intersect_list, function (a, b)
		return a.distance < b.distance
	end)

	-- Set the position of the box at the intersection point of the ray and the mesh.
	local p = intersect_list[1]
	local pos = ray.position+ray.direction*5
	if p and love.mouse.isDown(1) then
		self.player:set_position(p.point:unpack())
	end
	local x,z=0,0
	local angular=80/180*math.pi
	if love.keyboard.isDown('a') then
		x=x-1
	end
	if love.keyboard.isDown('d') then
		x=x+1
	end
	if love.keyboard.isDown('s') then
		z=z-1
	end
	if love.keyboard.isDown('w') then
		z=z+1
	end
	if love.keyboard.isDown('q') then
		self.y_angle=self.y_angle-dt*angular
	end
	if love.keyboard.isDown('e') then
		self.y_angle=self.y_angle+dt*angular
	end
	-- recursively update the scene nodes
	self:update_nodes(self.root_node, self.environment)
	-- self.angle = self.angle + dt*60
	self.time=self.time+dt
	local offset = self.eye_distance+math.sin(0*self.time)
	-- rotate the camera
	local q = quat.from_euler_angles(0, self.y_angle, self.x_angle) * vec3.unit_z * 2.0*offset
	local front_vec = -q*vec3(1,0,1)
	local side_vec = vec3.cross(front_vec,vec3.unit_y)
	local v = front_vec*z+x*side_vec
	-- center is lens, eye is orbit
	local move_step = math.min(self.eye_distance*1.5,100)
	self.camera.center =self.camera.center+ v:normalize()*dt*move_step
	self.camera.eye = q + self.camera.center
	self.camera:update_view_matrix()

	-- updating scene animations
	self.animations:update(dt)
end

function scene:wheelmoved(x,y)
	self.eye_distance=math.max(self.eye_distance-y,1.1)
end
return scene