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
	local pig_plane = menori.NodeTreeBuilder.create(pig_plane_model)[1]
	pig_plane:set_scale(2,2,2)

	-- build a scene node tree from the gltf data and initialize the animations
	local scenes = menori.NodeTreeBuilder.create(gltf, function (scene, builder)
		self.animations = menori.glTFAnimations(builder.animations)
		self.animations:set_action(1)
	end)
	local dog_gltf = menori.glTFLoader.load('examples/assets/simple_dog.glb')
	local model = menori.NodeTreeBuilder.create(dog_gltf, function (scene, builder)
		self.animations = menori.glTFAnimations(builder.animations)
		self.animations:set_action(1)
	end)[1]
	model:set_position(1,0,1)

	-- adding scene to the root node.
	self.root_node:attach(scenes[1])
	self.root_node:attach(model)
	self.root_node:attach(pig_plane)
	self.angle = 0
	self.time=0
	self.eye_distance=8
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
	print("mouse ray to ",ray)
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
		self.angle=self.angle+dt*angular
	end
	if love.keyboard.isDown('e') then
		self.angle=self.angle-dt*angular
	end
	-- recursively update the scene nodes
	self:update_nodes(self.root_node, self.environment)
	-- self.angle = self.angle + dt*60
	self.time=self.time+dt
	local offset = self.eye_distance+math.sin(0*self.time)
	-- rotate the camera
	local x_angle = math.rad(-40)
	local q = quat.from_euler_angles(0, self.angle, x_angle) * vec3.unit_z * 2.0*offset
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
	self.eye_distance=math.max(self.eye_distance-y,4.1)
end
return scene