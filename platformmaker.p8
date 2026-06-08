pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- main --

-- global --
block_types = {}
g = 1
p_sp = {} -- will be in level builder
bm = {}
pm = {}

p = {}
-- const --

-- var --


-- menu --
local m_p_sprts = {1,2,3}
local m_rect_cols = {0,10}

m_frm = 0
local m_p_sprt_i
local m_rect_col_i
local m_rect_dur

-- game
g_frm = 0

-- game over

function reset_var()
	-- var
	p_sp = {x=88,y=72}
	p = player:new({x=p_sp.x,y=p_sp.y,sprt=1})
	-- menu
	m_frm = 0
	m_p_sprt_i = 1
	m_rect_col_i = 1
	m_rect_dur = 15
	-- game
	g_frm = 0
	
	-- game_over
end

function _init()
	poke(0x5f2d,1)
	poke(0x5f2e,1)
	--pal({[0]=0,-15,1,-4,12,13,-1,7,2,-7,-8,8,9,-3,-2,-14},1)	reset_var()
	reset_var()
	--_update = update_menu
	--_draw = draw_menu
	_update = update_game
	_draw = draw_game
	
	-- debug
	block_types = {
			b_normal = b_normal,
			b_slime 	= b_slime,
			b_switch = b_switch,
			b_glass 	= b_glass,
			b_tnt    = b_tnt}

	bm = blocks_mng:new()
	
	bm:add_blocks(block_types.b_normal,200)
	bm:add_blocks(block_types.b_tnt,500)
	bm:add_blocks(block_types.b_slime,200)
	bm:add_blocks(block_types.b_switch,200)
	bm:add_blocks(block_types.b_glass,200)
	
	pm = particles_manager:new()
end

function update_menu()
	m_frm += 1
	if m_frm%m_rect_dur == 0 then
		m_rect_col_i = m_rect_col_i%#m_rect_cols+1 end
	if btnp(➡️) then
		m_p_sprt_i = m_p_sprt_i%#m_p_sprts+1
	elseif btnp(⬅️) then
		m_p_sprt_i = (m_p_sprt_i-2)%#m_p_sprts+1 
	end
	if btnp(🅾️) or btnp(❎) then
		p.sprt = m_p_sprts[m_p_sprt_i]
		_update = update_game
		_draw = draw_game
	end
end

function draw_menu()
	cls(2)
	print(block_types.b_normal.name,30,30)
	-- todo: automate distance
	local sp_y = 60
	local sp_x = {32,60,88}
	local pad = 6
	rectfill(sp_x[m_p_sprt_i]-pad+1,sp_y-pad+1,sp_x[m_p_sprt_i]+7+pad-1,sp_y+7+pad-1,m_rect_cols[2])
	for i=1,#m_p_sprts do
		spr(m_p_sprts[i],sp_x[i],sp_y)
	end
	rect(sp_x[m_p_sprt_i]-pad,sp_y-pad,sp_x[m_p_sprt_i]+7+pad,sp_y+7+pad,m_rect_cols[m_rect_col_i])
	print_ctr_w("🅾️ to select a character",90,7)
end

function update_game()
	g_frm += 1
	p:update()
	bm:update()
	pm:update()
end

function draw_game()
	cls(2)
	map(0,0,0,0,16,16)
	
	bm:draw()
	p:draw()
	pm:draw()
	
	print("★",118,40,10)
end
-->8
-- utils --

function print_ctr_w(s,y,col)
	local x = 64-(#s*4)/2
	print(s,64-#s*2,y,col)
end

function print_ctr_h(s,x,col)
	print(s,x,61,col)
end

function print_ctr(s,col)
	print(s,64-#s*2,61,col)
end

function pow(x,a)
	if (a==0) return 1
	if (a<0) x,a=1/x,-a
	local ret,a0,xn=1,flr(a),x
	a-=a0
	while a0>=1 do
		if (a0%2>=1) ret*=xn
		xn,a0=xn*xn,shr(a0,1)
	end
	while a>0 do
		while a<1 do x,a=sqrt(x),a+a end
		ret,a=ret*x,a-1
	end
	return ret
end

-- collisions
function collide_rect(ax, ay, aw, ah, bx, by, bw, bh)
	return ax < bx + bw and
        ax + aw > bx and
        ay < by + bh and
        ay + ah > by
end

-- x and y are center of circles
function collide_circle(x1,y1,r1,x2,y2,r2)
	local dx = x2-x1
	local dy = y2-y1
	local dist_sq = dx*dx+dy*dy
	local radius_sum = r1+r2
	return dist_sq < radius_sum*radius_sum
end

-- w,h should be 7,7 for 
-- normal 8x8 sprites
function collide_spr(x,y,w,h,f)
	local tl = {x=x,y=y}
	local br = {x=x+w,y=y+h}

	local tx1 = flr(tl.x/8)
	local ty1 = flr(tl.y/8)
	
	local tx2 = flr(br.x/8)
	local ty2 = flr(br.y/8)
	
	return fget(mget(tx1,ty1),f) or
								fget(mget(tx1,ty2),f) or
								fget(mget(tx2,ty1),f) or
								fget(mget(tx2,ty2),f)
end
-->8
-- player --

player = {
	-- vars to change --
	jump_vel = -8,
 max_fall = 8,
 weight = 1.4,
 max_vel_x = 3,
	accel = 2.7,
	ground_fric = 1.6, -- should be less than accel
	air_fric = 0.45,
	jump_buff_time = 5,
	coyote_time = 3,
	--------------------
	states = {jump=1,build=2,switch=3},
 x = 0,
 y = 0,
	sprt = 1,
	state = nil,
	vel_x = 0,
	vel_y = 0,
	grounded = false,
	jump_buff_curr = 0,
	jumped = false,
	coyote_curr = 0,
	-- build
	ptr_spd = 4,
	bx = 64,
	by = 64,
	lbx = 64,
	lby = 64,
	old_click = false,
	can_toggle = false,
	-- switch
	switch_time = 7,
	switch_curr = 0,
	switch_pressed = false,
	
	
	new = function(self,tbl)
		tbl = tbl or {}
		setmetatable(tbl,{__index=self})
		tbl.state = tbl.state or self.states.jump
		return tbl
	end,
	
	update = function(self)
		-- edit with func assignments!
		if self.state == self.states.build then
			self:build_mode()
		elseif self.state == self.states.jump then
			self:handle_input()
			self:check_collisions()
			self:apply_friction()
			self:apply_gravity()
			self:update_anim()
		elseif self.state == self.states.switch then
			self:switch_mode()
		end
	end,
	
	draw = function(self)
		spr(self.sprt,self.x,self.y)
		if self.state == self.states.build then
			rect(self.bx-self.bx%8,self.by-self.by%8,self.bx-self.bx%8+7,self.by-self.by%8+7,self.can_place and 10 or 8)
			spr(17,self.bx,self.by)
		end
		-- debug
		print(self:collide_blocks(self.x,self.y,8,8),100,110,7)
		print("velx: "..self.vel_x,75,90,10)
		print("vely: "..self.vel_y,75,100,10)
		print(self.x..";"..self.y,2,30,10)
		print(self.bx..";"..self.by,2,38,12)
		print(stat(32)..";"..stat(33),2,46,12)
		print(self.jumped,0,100,9)
		print(self.switch_curr,0,108,9)
	end,
	
	update_anim = function(self)
		-- todo
	end,
	
	handle_input = function(self)
		-- use functions instead of enum
		if btnp(❎) then
			self.state = self.states.build end
	
		local lx = self.x
		local ly = self.y
		
		if self:can_jump() then
			self.vel_y = self.jump_vel end
		self.y += self.vel_y
		self.y = flr(self.y)
		
		if self.y > 120 then
			self.y = 120
			self.vel_y = 0
		end		
		while self.y~=ly and 
								(collide_spr(self.x,self.y,7,7,0)
								or self:collide_blocks(self.x,self.y,8,8)) do
			if self.y < ly then
				self.y += 1
			elseif self.y > ly then
				self.y -= 1
			end
			self.vel_y = 0
		end
		
		self.grounded = self:on_ground()
		
		if btn(➡️) and self.vel_x < self.max_vel_x then
			print("inside ➡️",2,60,10)
			self.vel_x = min(self.max_vel_x,self.vel_x+self.accel)
		end
		if btn(⬅️) and self.vel_x > -self.max_vel_x then
			print("inside ⬅️",2,68,10)
			self.vel_x = max(-self.max_vel_x,self.vel_x-self.accel)
		end
		self.x += self.vel_x
		self.x = flr(self.x)

		if self.x < 0 then
			self.x = 0
			self.vel_x = 0
		elseif self.x > 120 then
			self.x = 120
			self.vel_x = 0
		end
		local b_coll = self:collide_blocks(self.x,self.y,8,8)
		local moved = false
		while self.x~=lx and 
								(collide_spr(self.x,self.y,7,7,0) 
								or b_coll) do
			if b_coll then	
				if b_coll.x < self.x then
					self.x = b_coll.x+8
					moved = true
				elseif b_coll.x > self.x then
					self.x = b_coll.x-8
					moved = true
				end
			end
			if not b_coll or (b_coll and not moved) then
				if self.x < lx then
					self.x += 1
				else
					self.x -= 1
				end
			end
			b_coll = self:collide_blocks(self.x,self.y,8,8)
			self.vel_x = 0
			moved = false
		end
	end,
	
	apply_friction = function(self)
		if self.grounded then
			if self.vel_x > 0 then
				self.vel_x = max(0,self.vel_x-self.ground_fric)
			elseif self.vel_x < 0 then
				self.vel_x = min(0,self.vel_x+self.ground_fric)
			end
		else
			if self.vel_x > 0 then
				self.vel_x = max(0,self.vel_x-self.air_fric)
			elseif self.vel_x < 0 then
				self.vel_x = min(0,self.vel_x+self.air_fric)
			end
		end
	end,
	
	build_mode = function(self)
		self.switch_pressed = false
		if btnp(❎) and self.switch_curr == 0 then
			--self.state = self.states.jump 
			self.switch_curr = 1
			self.switch_pressed = true
		elseif btn(❎) and self.switch_curr > 0 then
			self.switch_curr += 1
			self.switch_pressed = true
		end
		if not self.switch_pressed then
			if self.switch_curr > self.switch_time then
				self.state = self.states.switch
			elseif self.switch_curr > 0 then
				self.state = self.states.jump
			end
			self.switch_curr = 0
		end
		
		-- movement of pointer
		if flr(stat(32)) ~= self.lbx then
			self.bx = stat(32)
			self.lbx = self.bx
		end
		if flr(stat(33)) ~= self.lby then
			self.by = stat(33) 
			self.lby = self.by	
		end
		
		if btn(➡️) then
			self.bx += self.ptr_spd end
		if btn(⬅️) then
			self.bx -= self.ptr_spd end
		if btn(⬆️) then
			self.by -= self.ptr_spd end
		if btn(⬇️) then
			self.by += self.ptr_spd end
			
		self.bx = max(0,min(127,self.bx)) 
		self.by = max(0,min(127,self.by)) 
		--------
		
		-- can place --
		self.can_place = 
			not collide_rect(self.bx-self.bx%8,self.by-self.by%8,8,8,self.x,self.y,8,8)
			and not collide_spr(self.bx-self.bx%8,self.by-self.by%8,7,7,0)
		
		---------------
		
		local click = stat(34) == 1
		if not self.old_click and click and self.can_place then
			bm:toggle_block(self.bx-self.bx%8,self.by-self.by%8)
		end
		self.old_click = click
		
		if btnp(🅾️) and self.can_place then
			bm:toggle_block(self.bx-self.bx%8,self.by-self.by%8) end
	end,
	
	switch_mode = function(self) 
		if btnp(❎) then
			self.state = self.states.build end
		
		if btnp(➡️) then 
			bm:switch_block(1) end
		if btnp(⬅️) then
			bm:switch_block(-1) end
	end,
	
	check_collisions = function(self)
		-- todo
	end,
	
	collide_blocks = function(self,x,y,w,h)
		for k,v in pairs(bm.blocks) do
			if v.active and collide_rect(x,y,w,h,v.x,v.y,8,8) then
				v.collided = true
				return {x=v.x,y=v.y} 
			end
		end
		return false
	end,
	
	apply_gravity = function(self)
		if self.grounded then
			self.vel_y = 0 
			self.y = flr(self.y)
		else
			self.vel_y = min(self.max_fall,self.vel_y+g*self.weight)
		end
	end,
	
	can_jump = function(self)
		if self.jump_buff_curr > self.jump_buff_time then
			self.jump_buff_curr = 0
		elseif self.jump_buff_curr > 0 then
			self.jump_buff_curr += 1
		end
		
		if btnp(🅾️) then
			self.jump_buff_curr = 1
		end

		if self.grounded then
			if self.jump_buff_curr>0
					 and self.jump_buff_curr<self.jump_buff_time
					 then
				self.jump_buff_curr = 0
				self.jumped = true
				return true 
			else
				self.jumped = false
				self.coyote_curr = 0
			end
		else
			if self.coyote_curr<self.coyote_time
						and btnp(🅾️) 
						and not self.jumped then
				self.coyote_curr = self.coyote_time
				self.jumped = true
				return true
			end
			self.coyote_curr += 1
		end
		return false
	end,
	
	on_ground = function(self)
		return collide_spr(self.x,self.y+8,7,0.000001,0) 
			or self:collide_blocks(self.x,self.y+8,8,0.1)
	end,

}
-->8
-- blocks --

-- const



-- abstract base block
block = {
	name = "block",
	sprt_ui = 128,
	sprt = 129,
	
	x = 0,
	y = 0,
	placed = false,
	active = false,
	collided = false,
	
	new = function(self,tbl)
		tbl = tbl or {}
		setmetatable(
			tbl,
			{__index=self}
		)
		tbl:init()
		return tbl
	end,
	
	init = function(self)
		-- abstract
	end,
	
	update = function(self)
		-- abstract
	end,
	
	draw = function(self)
		if self.placed then
			spr(self.sprt,self.x,self.y) end
	end,
	
	place = function(self,x,y)
		self.x = x
		self.y = y
		self.placed = true
		self.active = true
	end,
	
	remove = function(self)
		self.placed = false
		self.active = false
	end,
}

b_normal = block:new({
	name = "b_normal",
	sprt_ui = 128,
	sprt = 129,
})

b_slime = block:new({
	name = "b_slime",
	sprt_ui = 130,
	sprt = 131,
	vel_y = -10,
	p_jumped_frm = 0,
	
	update = function(self)
		if self.p_jumped_frm == 1 then
			self.p_jumped_frm = 0
			p.jumped = true
		end
		if self.active and collide_rect(p.x,p.y,8,8,self.x,self.y-0.01,8,2) then
			p.vel_y = self.vel_y
			p.jumped = true
			self.p_jumped_frm = 1
		end
		--[[
		-- delete test --
		if collide_rect(p.x,p.y,8,8,self.x-0.01,self.y,8,8) then
			p.vel_x = -16
		elseif collide_rect(p.x,p.y,8,8,self.x+7,self.y,1.01,8) then
			p.vel_x = 16
		end
		-- end  delete]] --
		--]]
	end,
})

-- if more colors are added
-- we can use this as a 
-- parent class
b_switch = block:new({
	name = "b_switch",
	sprt_ui = 132,
	sprt = {on=133,off=134},
	dur = 100, -- frames
	in_active = false,
	
	init = function(self)
		self.in_active = flr(g_frm/self.dur)%2 == 0
	end,
	
	update = function(self)
		if g_frm%self.dur == 0 then
			self.in_active = not self.in_active
			if self.placed then
				if not self.in_active then
					self.active = self.in_active 
				elseif not collide_rect(self.x,self.y,8,8,p.x,p.y,8,8) then
					self.active = self.in_active
				end
			end
		elseif self.in_active 
									and not collide_rect(self.x,self.y,8,8,p.x,p.y,8,8)
									and self.placed then
			self.active = self.in_active
		end
	end,
	
	draw = function(self)
		if self.placed then
			local s
			if self.active then
				s = self.sprt.on
			else
				s = self.sprt.off
			end
			spr(s,self.x,self.y) end
	end,
})

b_glass = block:new({
	name = "b_glass",
	sprt_ui = 135,
	sprt = {136,137},
	sprt_act = 136,
	dur = 30, -- frames
	resp = 70,
	frm = 0,
	
	update = function(self)
		self.frm += (self.frm>0) and 1 or 0
		if self.active then
			if self.frm == self.dur\2 then
				self.sprt_act = self.sprt[2]
			elseif self.frm == self.dur then
				self.active = false
			end
		elseif self.frm >= self.dur+self.resp 
									and not collide_rect(self.x,self.y-0.01,8,2,p.x,p.y,8,8) then
			self.active = true
			self.frm = 0
			self.sprt_act = self.sprt[1]
		end
		if self.placed and collide_rect(self.x,self.y-0.01,8,2,p.x,p.y,8,8) then
			self.frm = (self.frm>0) and self.frm or 1 end
	end,
	
	draw = function(self)
		if self.placed and self.active then
			spr(self.sprt_act,self.x,self.y) end
	end,
})

b_tnt = block:new({
	name = "b_tnt",
	sprt_ui = 138,
	sprt = 139,
	
	max_vel = 20, -- max vel added to x and y
	parts_n = 30,
	
	update = function(self)
		--if self.active and collide_rect(p.x,p.y,8,8,self.x-0.01,self.y-0.01,8.02,8.02) then
		if self.active and self.collided then
			local diffx = p.x-self.x
			local diffy = p.y-self.y
			p.vel_x = diffx/8*self.max_vel
			p.vel_y = diffy/8*self.max_vel
			self.collided = false
			self.active = false
			for i=1,self.parts_n do
				pm:add_particle(particle:new({
					x = self.x+4,
					y = self.y+4,
					l = 20+rnd(10),
					r = rnd(2),
					minvel = 0.5,
					col = rnd({9,10}),
					velx = rnd(5)-rnd(5),
					vely = rnd(1)-rnd(5),
					weight = 0.4,
				}))
			end
			sfx(0)
		end
	end,
	
	draw = function(self)
		if self.placed and self.active then
			spr(self.sprt,self.x,self.y) end
	end,
})
-->8
-- blocks manager --

blocks_mng = {
	blocks_unplaced = {},
	blocks = {},
	selected_i = 1,
	-- switch vars
	switch_arr_time = 3,
	arr_vel_y = 1.5,
	arr_max_y = 3,
	sprt_arr = 18,
	switch_frm = 0,
	arr_dir = 1,
	arr_y = 0,
	
	new = function(self)
		local tbl = {}
		setmetatable(
			tbl,
			{__index=self})
		return tbl
	end,
	
	update = function(self)
		for b in all(self.blocks) do
			b:update()
		end
	end,
	
	draw = function(self)
		for b in all(self.blocks) do
			b:draw()
		end
		local x = 0
		for b in all(self.blocks) do
			if b.placed then
				x += 1 end
		end
		print(x,2,10,7)
		local lmarg = 25
		local pad = 10
		local i = 0
		local ui_b_pos = {}
		for k,v in pairs(self.blocks_unplaced) do
			if i+1 ~= self.selected_i then
				print(v.n,2+lmarg*i+pad*i,3,7)
			else
				print(v.n,2+lmarg*i+pad*i,3,10)
			end
			local s = ""..v.n
			spr(v.b_type.sprt_ui,2+lmarg*i+pad*i+#s*4,2)
			ui_b_pos[i+1] = {x=2+lmarg*i+pad*i+#s*4,y=2}
			i += 1
		end
		
		-- switch mode
		if p.state == p.states.switch then
			self:draw_switch_mode(ui_b_pos)
		end
	end,
	
	draw_switch_mode = function(self,ui_b_pos)
		self.switch_frm += 1
			if self.switch_frm%self.switch_arr_time == 0 then
				self.arr_y += self.arr_vel_y*self.arr_dir
				if self.arr_y+(self.arr_vel_y*self.arr_dir) > self.arr_max_y then
					self.arr_y = self.arr_max_y
					self.arr_dir *= -1
				elseif self.arr_y+(self.arr_vel_y*self.arr_dir) < 0 then
					self.arr_y = 0
					self.arr_dir *= -1
				end
			end
			spr(self.sprt_arr,ui_b_pos[self.selected_i].x,ui_b_pos[self.selected_i].y+self.arr_y+8)
	end,
	
	add_blocks = function(self,b_type,n)
		for k,v in pairs(self.blocks_unplaced) do
			if v.b_type.name == b_type.name then
				v.n += n
				return
			end
		end
		add(self.blocks_unplaced,{b_type=b_type,n=n})
		for i=1,n do
			add(self.blocks,b_type:new())
		end
	end,
	
	toggle_block = function(self,x,y)
		for b in all(self.blocks) do
			if b.placed and b.x == x and b.y == y then
				self:remove_block(x,y)
				return
			end
		end
		self:try_place_block(x,y)
	end,
	
	try_place_block = function(self,x,y)
		local placed = false
		if self.blocks_unplaced[self.selected_i].n > 0 then
			self.blocks_unplaced[self.selected_i].n -= 1
			for b in all(self.blocks) do
				if self:can_place(b) then
					b:place(x,y)
					break
				end
			end
			placed = true
		end
		return placed
	end,
	
	can_place = function(self,b)
		return not b.placed and
			b.name == self.blocks_unplaced[self.selected_i].b_type.name
	end,
	
	remove_block = function(self,x,y)
		-- check for its hp before 
		-- putting it back in the
		-- unplaced_blocks table
		for b in all(self.blocks) do
			if b.x == x and b.y == y then
				b:remove()
				break
			end
		end
	end,
	
	switch_block = function(self,dir)
		if dir == 1 then
			self.selected_i = self.selected_i%#self.blocks_unplaced+1
		elseif dir == -1 then
			self.selected_i = (self.selected_i-2)%#self.blocks_unplaced+1
		end
	end,
	
	-- returns idx of type in 
	-- table unplaced_blocks
	get_type_idx = function(self,b)
		local i = 1
		for t in all(self.unplaced_blocks) do
			if t.name == b.name then
				return i end
			i += 1
		end
		return -1
	end
}
-->8
-- particles --

particle = {
	x = 0,
	y = 0,
	col = 9,
	r = 0,
	velx = 2,
	vely = 2,
	weight = 1,
	l = 10,
	minvel = 0.5,
	
	new = function(self,tbl)
  tbl = tbl or {}
		setmetatable(tbl,particle_mt)  
  if abs(tbl.velx) < tbl.minvel then
   tbl.velx = sgn(tbl.velx)*tbl.minvel end
  if abs(tbl.vely) < tbl.minvel then
   tbl.vely = sgn(tbl.vely)*tbl.minvel end
  return tbl
	end,
	
	update = function(self)
		self.x += self.velx
		self.vely += g*self.weight
		self.y += self.vely
		self.l -= 1
	end,
	
	draw = function(self)
		circfill(self.x,self.y,self.r,self.col)
	end,
}

particle_mt = {__index=particle}


particles_manager = {
	parts = {},
	
	new = function(self,tbl)
		tbl = tbl or {}
		setmetatable(tbl,{__index=self})
		tbl.parts = tbl.parts or {}
		return tbl
	end,
	
	update = function(self) 
		for p in all(self.parts) do 
			p:update()
			if (p.l < 0) del(self.parts,p)
		end
	end,
	
	draw = function(self)
		for p in all(self.parts) do 
			p:draw()
		end
	end,
	
	add_particle = function(self,p) 
		add(self.parts,p)
	end,
}
__gfx__
0000000088888888bbbbbbbbcccccccc0000000008888880000000000bbbbbb0000000000cccccc0eeeeeeee000000000eeeeee0000000000000000000000000
000000001111111111111111111111118888888801111110bbbbbbbb01111110cccccccc0111111011111111eeeeeeee01111110000000000000000000000000
00000000122112211221122112211221111111110121121011111111012112101111111101211210122112211111111101211210000000000000000000000000
00000000122112211221122112211221122112210121121012211221012112101221122101211210122112211221122101211210000000000000000000000000
00000000111111111111111111111111122112210111111012211221011111101221122101111110111111111221122101111110000000000000000000000000
0000000081888888b1bbbbbbc1cccccc11111111018888801111111101bbbbb01111111101ccccc0e1eeeeee1111111101eeeee0000000000000000000000000
00000000188888881bbbbbbb1ccccccc8188888801888880b1bbbbbb01bbbbb0c1cccccc01ccccc01eeeeeeee1eeeeee01eeeee0000000000000000000000000
0000000088888888bbbbbbbbcccccccc18888888088888801bbbbbbb0bbbbbb01ccccccc0cccccc0eeeeeeee1eeeeeee0eeeeee0000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000171000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000177100000018810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000177710000189981000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000177771000199661000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000177110001899988100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011710001889988100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c77c7c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc7ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc7ccc7c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007777770000000004444444400000000bbbbbbbbbb0bb0bb000000007777777777777757000000008885f88800000000000000000000000000000000
0077770073333337004444004444444407077070bbbbbbbbb000000b077777707cc7ccc77cc7c5c70885f880888f588800000000000000000000000000000000
0733337073333337074444704444444400bbbb00bbbbbbbb0000000007cc7c707c7cc7c75c755757088f5880888ff58800000000000000000000000000000000
0733337073333337078888708888888807bbbb70bbbbbbbbb000000b07c7cc707ccc7cc7755c7cc5088ff580888ff58800000000000000000000000000000000
0733337073333337078888708888888807bbbb70bbbbbbbbb000000b077cc7707cc7ccc75c5755c5088ff5808885588800000000000000000000000000000000
0733337073333337078888708888888800bbbb00bbbbbbbb0000000007cc7c707c7cc7c77c75c5c7088ff980885ff88800000000000000000000000000000000
0077770073333337007777008888888807077070bbbbbbbbb000000b077777707ccc7cc7755c7c57088ff880889ff88800000000000000000000000000000000
0000000007777770000000008888888800000000bbbbbbbbbb0bb0bb00000000777777775777775700000000888ff88800000000000000000000000000000000
__gff__
0002020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000131313131313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000025650286502c6502e6503165034650376503a6503c6503e6503f6503b65037650336502e65029650246501f6501a650146500f6500a65004650006500060007600046000160001600272002720000000
00010000206502465027650296502b6502d6502f6503065031650316503265031650306502f6502c6502b650296502765025650226501f6501d6501a6501665012650106500e6500c6500a650086500665006650
