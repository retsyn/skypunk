-- title:   Skypunk
-- author:  Retsyn
-- desc:    Let's Shmup!
-- site:    website link
-- license: 
-- version: 0.1
-- script:  lua
-- input: gamepad

-- enumerated constants:
sprite_ids = {
	skypunk = 256,
	ratboy = 288,

	explo = 368,
	enemy_bullet = 384,
	player_bullet = 386,
}

screen_limit = {
	left = 0,
	top = 0,
	bottom = 136,
	right = 240
}

minds = {
	player = 0,
	ratboy = 1,
}

-- MATH FUNCS for aiming bullets
-- Find the line vector between two objects.
function GetVector(x1, y1, x2, y2)
	lx = (x2 - x1)
	ly = (y2 - y1)
	return {lx, ly}
end

-- Find the magnitude of a vector (So we can normalize it later for shot angles)
function Magnitude(x, y)
	magnitude = math.sqrt((x^2) + (y^2))
	return magnitude -- Pop pop.
end

-- A full line between two objects is reduced to a "pixel length" x,y vector,
-- which can be multiplied by the speed of the projectile.
function NormalizeVector(x, y)
	mag = Magnitude(x, y)
	normx = x / mag
	normy = y / mag
	return {normx, normy}
end

-- Calculates shot velocities for any aim using the above functions.
function AimShot(x1, y1, x2, y2, speed)
	line_vec = GetVector(x1, y1, x2, y2) -- Line between shooter and target.
	norm_vec = NormalizeVector(line_vec[1], line_vec[2]) -- shorten this line to a 'unit'
	return {norm_vec[1] * speed, norm_vec[2] * speed} -- multiple the unit by desired speed.
end

-- lua table-size util
function Len(table)
	local size = 0
	for _ in pairs(table) do
		size = size + 1
	end
	return size
end

-- Animation data for each object:
Animation_data = {
	skypunk = {{0}, {1}, {2}}, -- straight, up, down
	explode = {{0, 1, 2, 3, 4, 5, 6, 7, 8}},
	ratboy = {{0}} -- just static?
}

function Diminish(float, factor)
	-- function to move towards zero by a given factor, but not past it.  Good for friction.
	if(float > 0) then
		if(math.abs(float) < factor) then 
			float = 0
		else
			float = float - factor
		end
	elseif(float < 0) then
		if(math.abs(float) < factor) then
			float = 0
		else
			float = float + factor
		end
	end
	return float
end

-- Projectile master table and class
projs =  {}

function projs:new(newsprite, newx, newy, new_x_vel, new_y_vel, new_flash)
	new_proj = {
		sprite = newsprite,
		x = newx,
		y = newy,
		x_vel = new_x_vel,
		y_vel = new_y_vel,
		flash = new_flash,
		frame = 0,
		tick = 0,
		alive = true,
	}

	function new_proj:move()
		self.x = self.x + self.x_vel
		self.y = self.y + self.y_vel
		-- We add four pixels to the screen limit to give room to scroll off.
		if(self.x > screen_limit.right + 4 or self.x < -4) then 
			self.alive = false 
		end
		if(self.y > screen_limit.bottom + 4 or self.y < -4) then
			self.alive = false
		end

	end

	function new_proj:draw()
		spr(self.sprite + self.frame, self.x-4, self.y-4, nil, 1, nil, nil, 1, 1)
		if(self.flash) then
			self.tick = self.tick + 1
			if(self.tick >= 5) then
				if(self.frame == 0) then self.frame = 1 else self.frame = 0 end
				self.tick = 0
			end
		end
	end

	table.insert(self, new_proj)
end


-- Entity master table and class
ents = {}
function ents:new(newsprite, newsize, newmind, newx, newy, new_anims)
	-- Process optional args
	if(new_anims == nil) then
		new_anims = {{0, 1, 0, 2}}
	end
	-- Fresh ent table; basic stats
	ent = {
		sprite = newsprite, -- Type ID (inexorable from type)
		size = newsize,
		mind = newmind, -- control ID, zero is "playable"
		drawframe = newsprite, -- Which frame of animation should draw now.
		animations = new_anims, -- Multiple "reels" of animation.
		anim_reel = 1, -- Which "reel" from animations to play.
		animframe = 0, -- Which in the play frames sequence are we drawing.
		tick = 0, -- Tick timer every in-game frame to set anim speed.
		animspeed = 20, -- Frames in engine until animation next frame
		x = newx, -- X screen location
		y = newy, -- Y screen location

		-- Physics stuff
		x_vel = 0.0, -- horizontal velocity
		y_vel = 0.0, -- vertical velocity
		airspeed = 0.5,
		airfriction = 0.3,
		maxairspeed = 0.8,
		impulses = {
			up=false,
			down=false,
			left=false,
			right=false,
			attack=false,
			dodge=false,
			special=false,
		}, -- impulses are "intentions" of an entity, whether from ai 
		-- or player's controller input.

		-- Game mechanic stuff
		destroyable = true, -- if truly deleting this is allowed, as in not a player.
		alive = true, -- if not true, queue for deletion.
	}

	-- Functions that work on all ents:
	function ent:animate()
		-- Iterate the ticker to see if it's time to advance a frame.
		self.tick = self.tick + 1
		if(self.tick >= self.animspeed) then
			-- If it's time to advance a frame, 'animframe' goes up by 1.
			self.animframe = self.animframe + 1
			self.tick = 0
			-- the playframes table has a list of offsets, found with animframe.
			-- First make sure we haven't counted past the last frame:
			if(self.animframe > Len(self.animations[self.anim_reel])) then
				self.animframe = 1
			end
			-- Drawing the frame offset from the playframes list, add it to the spr index
			self.drawframe = self.sprite + (self.animations[self.anim_reel][self.animframe] * self.size)
		end

		-- how we animate the player.
		if(self.sprite == sprite_ids.skypunk) then
			if(self.impulses.up == true and self.impulses.down == false) then
				self.anim_reel = 3
				self.tick = self.animspeed
			elseif(self.impulses.down == true and self.impulses.up == false) then
				self.anim_reel = 2
				self.tick = self.animspeed
			else
				self.anim_reel = 1
				self.tick = self.animspeed
			end
		end

	end


	function ent:think()
		-- Make it think!  Also, for think=0, get player input.

		-- clean out all impulses:
		for i,e in ipairs(self.impulses) do
			self.impulses[i] = false
		end

		-- PLAYER!
		if(self.mind == minds.player) then
			self.impulses.up = btn(0)
			self.impulses.down = btn(1)
			self.impulses.left = btn(2)
			self.impulses.right = btn(3)
			self.impulses.attack = btnp(4)
			self.impulses.dodge = btnp(5)
			self.impulses.special = btnp(6)
		end
	end


	function ent:act()
		-- Make it act on the impulses, from AI or controller alike.
		if(self.impulses.up) then self.y_vel = self.y_vel - self.airspeed end
		if(self.impulses.down) then self.y_vel = self.y_vel + self.airspeed end 
		if(self.impulses.left) then self.x_vel = self.x_vel - self.airspeed end
		if(self.impulses.right) then self.x_vel = self.x_vel + self.airspeed end
	end


	function ent:phys()
		-- Apply velocities, friction, and collision for an ent.

		-- Cap velocity at top speed:
		if(self.x_vel > self.maxairspeed) then 
			self.x_vel = self.maxairspeed 
		elseif(self.x_vel < -self.maxairspeed) then
			self.x_vel = -self.maxairspeed
		end
		if(self.y_vel > self.maxairspeed) then 
			self.y_vel = self.maxairspeed 
		elseif(self.y_vel < -self.maxairspeed) then
			self.y_vel = -self.maxairspeed
		end
		
		-- Stack the velocity on:
		self.x = self.x + self.x_vel
		self.y = self.y + self.y_vel

		-- Apply friction.
		self.x_vel = Diminish(self.x_vel, self.airfriction)
		self.y_vel = Diminish(self.y_vel, self.airfriction)
 
	end


	function ent:draw()
		-- Render the sprite with the Consoles draw command.
		-- Tic80 syntax
		spr(self.drawframe, self.x-8, self.y-8, nil, 1, nil, nil, self.size, self.size)

	end
	table.insert(self, ent) -- Put self new ent in the ents list.
end


function init()
	-- make a player in the ent table:
	ents:new(sprite_ids.skypunk, 2, minds.player, 0, 0, Animation_data.skypunk)
	ents[1].destroyable = false -- Mark player as not delete-able


	-- TEMP STUFF
	-- make some ratboys
	ents:new(sprite_ids.ratboy, 2, minds.ratboy, 120, 20, Animation_data.ratboy)
	ents:new(sprite_ids.ratboy, 2, minds.ratboy, 160, 30, Animation_data.ratboy)
	ents:new(sprite_ids.ratboy, 2, minds.ratboy, 175, 10, Animation_data.ratboy)

end


init()
shottick = 0

function TIC()
	-- clear the screen
	cls(10)
	shottick = shottick + 1
	if(shottick >= 10) then
		vel = AimShot(60, 60, ents[1].x, ents[1].y, 1.3)
		projs:new(sprite_ids.enemy_bullet, 60, 60, vel[1], vel[2], true)
		shottick = 0
	end

	for i, e in ipairs(ents) do
		ents[i]:think()
		ents[i]:animate()
		ents[i]:act()
		ents[i]:phys()
		ents[i]:draw()
		if(ents[i].alive == false) then table.remove(ents, i) end
	end

	for i, e in ipairs(projs) do
		projs[i]:move()
		projs[i]:draw()
		if(projs[i].alive == false) then table.remove(projs, i) end
	end

	print(Len(projs), 10, 10)
end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <SPRITES>
-- 000:0000000000000002000000cc000000cc000000dc000000dd066000dd6666000d
-- 001:2ccd00002cccd0002cccc000cc330000c2112000d26f20002222100f3223000f
-- 002:000000000000000000000002000000cc000000cc000000dc000000dd066000dd
-- 003:000000002ccd00002cccd0002cccc000cc330000c2112000d26f200f2222100f
-- 004:000000000000000000000002000000cc000000cc000000dc000000dd06600007
-- 005:000000002ccd00002cccd0002cccc000cc330000c2112000777f200f7777000f
-- 016:6666066655566555066666660007767700000777000000000000000000000000
-- 017:6666600f555556dd666666087777670877777008fccf0000fccf0000ffff0000
-- 018:6666066d66666666555567550557765500000775000000000000000000000000
-- 019:3223600f666666dd555576085555670855557008555f0000ffff000000000000
-- 020:6776067777776777066666660007767700000777000000000000000000000000
-- 021:7777600f777756dd66666608feef6708fccf7008fccf0000ffff000000000000
-- 032:00000000000000ed000000dd000000dd000000ed0000000e0220000022220000
-- 033:00000000de000000dd00000042cc000042cf0000dddddf00dddde00fedde000f
-- 048:2222022233322333022222220001121100000111000000000000000000000000
-- 049:2222200f333332dd222222081111210811111008fccf0000fccf0000ffff0000
-- 112:000000000000000000033000003cc300003cc300000330000000000000000000
-- 113:000000000033330003cccc300cccccc00cccccc0033cc3300003300000000000
-- 114:004444004cccccc4cccccccccccccccccccccccc4cccccc44c4cc4c400044000
-- 115:0044440034cccc434cccccc44cc44cc44cccccc44c4cc4c43434434300033000
-- 116:00333300334cc433344444433c4444c3343443433333333333eeee33000ee000
-- 117:01222210122222211222222112122121e1e11e1e0eeeeee0000ee00000000000
-- 118:0111111011111111e1e11e1eeee11eeeffefefff0ffffff0000ff00000000000
-- 119:0f0ff0f0ffffffff0f0ffff00000000000000000000000000000000000000000
-- 120:0f0ff0f000000000000000000000000000000000000000000000000000000000
-- 128:000000000005500000544500054cc450054cc450005445000005500000000000
-- 129:0000000000044000004cc40004c55c4004c55c40004cc4000004400000000000
-- 130:0000000000000000001044401020cccc1020cccc001044400000000000000000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57fabed261daa500918508556d29366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

