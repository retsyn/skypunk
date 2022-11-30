-- title:   Skypunk
-- author:  Retsyn
-- desc:    Let's Shmup!
-- site:    website link
-- license: 
-- version: 0.1
-- script:  lua
-- input: gamepad

-- enumerated constants:
entity_ids = {
	skypunk = 256,

	enemy_bullet = 384,
	player_bullet = 386,
}

minds = {
	player = 0,
}

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
		flash = new_flash
	}

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
		} -- impulses are "intentions" of an entity, whether from ai 
		-- or player's controller input.
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
		if(self.sprite == entity_ids.skypunk) then
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
		spr(self.drawframe, self.x, self.y, nil, 1, nil, nil, self.size, self.size)

	end
	table.insert(self, ent) -- Put self new ent in the ents list.
end


function init()
	-- make a player in the ent table:
	ents:new(entity_ids.skypunk, 2, minds.player, 20, 30, Animation_data.skypunk)
end


init()

function TIC()
	-- clear the screen
	cls(10)

	for i, e in ipairs(ents) do
		ents[i]:think()
		ents[i]:animate()
		ents[i]:act()
		ents[i]:phys()
		ents[i]:draw()
	end
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

