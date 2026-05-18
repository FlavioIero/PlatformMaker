pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- main --

-- global --

-- const --

-- var --

-- menu --
local m_p_sprts = {1,2,3}
local m_rect_cols = {0,10}

local m_frm
local m_p_sprt_i
local m_rect_col_i
local m_rect_dur
-- game

-- game over

function reset_var()
	-- menu
	m_frm = 0
	m_p_sprt_i = 1
	m_rect_col_i = 1
	m_rect_dur = 15
	-- game
	
	
	-- game_over
end

function _init()
	reset_var()
	_update = update_menu
	_draw = draw_menu
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
end

function draw_menu()
	cls()
	-- todo: automate distance
	local sp_y = 60
	local sp_x = {32,60,88}
	local pad = 6
	rectfill(sp_x[m_p_sprt_i]-pad+1,sp_y-pad+1,sp_x[m_p_sprt_i]+7+pad-1,sp_y+7+pad-1,9)
	for i=1,#m_p_sprts do
		spr(m_p_sprts[i],sp_x[i],sp_y)
	end
	rect(sp_x[m_p_sprt_i]-pad,sp_y-pad,sp_x[m_p_sprt_i]+7+pad,sp_y+7+pad,m_rect_cols[m_rect_col_i])
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

function collide_circle(x1,y1,r1,x2,y2,r2)
	local dx = x2-x1
	local dy = y2-y1
	local dist_sq = dx*dx+dy*dy
	local radius_sum = r1+r2
	return dist_sq < radius_sum*radius_sum
end

function collide_spr(pos,f)
	local tl = pos:clone()
	local br = pos:clone()+vector2.new(7,7)

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
-- vector2 --

vector2 = {}
vector2.__index = vector2

function vector2.new(x,y)
	return setmetatable({x=x,y=y},vector2)
end

function vector2.__tostring(v)
	return "("..v.x..", "..v.y..")"
end 

function vector2.__eq(v1,v2)
	return v1.x == v2.x and v1.y == v2.y
end

function vector2.__add(v1,v2)
	return vector2.new(v1.x+v2.x,v1.y+v2.y)
end

function vector2.__mul(v1,v2)
	return vector2.new(v1.x*v2.x,v1.y*v2.y)
end

function vector2:clone()
	return vector2.new(self.x,self.y)
end

function vector2:dist(v)
	dx = abs(self.x-v.x)
	dy = abs(self.y-v.y)
	ma = max(dx,dy)
	mi = min(dx,dy)
	if ma == 0 then return 0 end
	return ma*sqrt(1+(mi/ma)*(mi/ma))
end

__gfx__
0000000088888888bbbbbbbbcccccccc0000000008888880000000000bbbbbb0000000000cccccc0eeeeeeee000000000eeeeee0000000000000000000000000
000000001111111111111111111111118888888801111110bbbbbbbb01111110cccccccc0111111011111111eeeeeeee01111110000000000000000000000000
00700700122112211221122112211221111111110121121011111111012112101111111101211210122112211111111101211210000000000000000000000000
00077000122112211221122112211221122112210121121012211221012112101221122101211210122112211221122101211210000000000000000000000000
00077000111111111111111111111111122112210111111012211221011111101221122101111110111111111221122101111110000000000000000000000000
0070070081888888b1bbbbbbc1cccccc11111111018888801111111101bbbbb01111111101ccccc0e1eeeeee1111111101eeeee0000000000000000000000000
00000000188888881bbbbbbb1ccccccc8188888801888880b1bbbbbb01bbbbb0c1cccccc01ccccc01eeeeeeee1eeeeee01eeeee0000000000000000000000000
0000000088888888bbbbbbbbcccccccc18888888088888801bbbbbbb0bbbbbb01ccccccc0cccccc0eeeeeeee1eeeeeee0eeeeee0000000000000000000000000
