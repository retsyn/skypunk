-- title:   Skypunk
-- author:  Retsyn
-- desc:    Let's Shmup!
-- site:    website link
-- license: 
-- version: 0.1
-- script:  lua

-- Entity master table and class
ents = {}
function ents:new(type, mind, newx, newy)

	-- Fresh ent table; basic stats
	ent = {
		sprite = newsprite, -- Type ID (inexorable from type)
		mind = 0, -- control ID, zero is "playable"
		drawframe = 0, -- Which frame of animation should draw now.
		playframes = {0, 1, 2}, -- Which frames to offset from the sprite.
		animframe = 0, -- Which in the play frames sequence are we drawing.
		tick = 0, -- Tick timer every in-game frame to set anim speed.
		animspeed = 5, -- Frames in engine until animation next frame
		x = newx, -- X screen location
		y = newy, -- Y screen location
		x_vel = 0.0, -- horizontal velocity
		y_vel = 0.0, -- vertical velocity
	}
	-- Functions that work on all ents:
	function ent:animate()
		-- Iterate the ticker to see if it's time to advance a frame.
		this.tick = this.tick + 1
		if(this.tick >= animspeed) then
			-- If it's time to advance a frame, 'animframe' goes up by 1.
			this.animframe = this.animframe + 1
			this.tick = 0
			-- the playframes table has a list of offsets, found with animframe.
			this.drawframe = sprite + this.playframe[animframe]
			-- If we pull 'nil' from the playframe list, then it's ran out.
			if(this.drawframe == nil) then
				-- If the play frame list has ran out, we move ahead.
				this.animframe = 1
				this.drawframe = sprite + this.playframe[animframe]
			end
		end
	end
	table.insert(this, ent) -- Put this new ent in the ents list.
end

function TIC()

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
-- 001:0000000000000002000000cc000000cc000000dc000000dd099000dd9999000d
-- 002:2ccd00002cccd0002cccc000cc330000c2112000d26f20002222100c3223000c
-- 003:000000000000000000000002000000cc000000cc000000dc000000dd099000dd
-- 004:000000002ccd00002cccd0002cccc000cc330000c2112000d26f200c2222100c
-- 005:000000000000000000000002000000cc000000cc000000dc000000dd09900008
-- 006:000000002ccd00002cccd0002cccc000cc330000c2112000888f200c8888000c
-- 017:99990999aaa99aaa099999990008898800000888000000000000000000000000
-- 018:9999900caaaaa9dd9999990c8888980c8888800cfccf0000fccf0000ffff0000
-- 019:9999099d99999999aaaa98aa0aa889aa0000088a000000000000000000000000
-- 020:3223900c999999ddaaaa890caaaa980caaaa800caaaf0000ffff000000000000
-- 021:9889098888889888099999990008898800000888000000000000000000000000
-- 022:8888900c8888a9dd9999990cfeef980cfccf800cfccf0000ffff000000000000
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
-- 000:1a1c2c5d275db13e53ef7d57fabed2a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

