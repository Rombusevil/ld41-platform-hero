pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
-- made with super-fast-framework
------------------------- Start Imports
function bbox(w,h,xoff1,yoff1,xoff2,yoff2)
    local bbox={}
    bbox.offsets={xoff1 or 0,yoff1 or 0,xoff2 or 0,yoff2 or 0}
    bbox.w=w
    bbox.h=h
    bbox.xoff1=bbox.offsets[1]
    bbox.yoff1=bbox.offsets[2]
    bbox.xoff2=bbox.offsets[3]
    bbox.yoff2=bbox.offsets[4]
    function bbox:setx(x)
        self.xoff1=x+self.offsets[1]
        self.xoff2=x+self.w-self.offsets[3]
    end
    function bbox:sety(y)
        self.yoff1=y+self.offsets[2]
        self.yoff2=y+self.h-self.offsets[4]
    end
    function bbox:printbounds()
        rect(self.xoff1, self.yoff1, self.xoff2, self.yoff2, 8)
    end
    return bbox
end
function anim()
    local a={}
	a.list={}
	a.current=false
	a.tick=0
    function a:_get_fr(one_shot, callback)
		local anim=self.current
		local aspeed=anim.speed
		local fq=anim.fr_cant		
		local st=anim.first_fr
		local step=flr(self.tick)*anim.w
		local sp=st+step
		self.tick+=aspeed
		local new_step=flr(flr(self.tick)*anim.w)		
		if st+new_step >= st+(fq*anim.w) then 
		    if one_shot then
		        self.tick-=aspeed  
		        callback()
		    else
		        self.tick=0
		    end
		end
		return sp
    end
    function a:set_anim(idx)
        if (self.currentidx == nil or idx != self.currentidx) self.tick=0 
        self.current=self.list[idx]
        self.currentidx=idx
    end
	function a:add(first_fr, fr_cant, speed, zoomw, zoomh, one_shot, callback)
		local a={}
		a.first_fr=first_fr
		a.fr_cant=fr_cant
		a.speed=speed
		a.w=zoomw
        a.h=zoomh
        a.callback=callback or function()end
        a.one_shot=one_shot or false
		add(self.list, a)
	end
	function a:draw(x,y,flipx,flipy)
		local anim=self.current
		if( not anim )then
			rectfill(0,117, 128,128, 8)
			print("err: obj without animation!!!", 2, 119, 10)
			return
		end
		spr(self:_get_fr(self.current.one_shot, self.current.callback),x,y,anim.w,anim.h,flipx,flipy)
    end
	return a
end
function entity(anim_obj)
    local e={}
    e.x=0
    e.y=0
    e.anim_obj=anim_obj
    e.debugbounds, e.flipx, e.flipy = false
    e.bounds=nil
    e.flickerer={}
    e.flickerer.timer=0
    e.flickerer.duration=0          
    e.flickerer.slowness=3
    e.flickerer.is_flickering=false 
    function e.flickerer:flicker()
        if(self.timer > self.duration) then
            self.timer=0 
            self.is_flickering=false
        else
            self.timer+=1
        end
    end
    function e:setx(x)
        self.x=x
        if(self.bounds != nil) self.bounds:setx(x)
    end
    function e:sety(y)
        self.y=y
        if(self.bounds != nil) self.bounds:sety(y)
    end
    function e:setpos(x,y)
        self:setx(x)
        self:sety(y)
    end
    function e:set_anim(idx)
		self.anim_obj:set_anim(idx)
    end
    function e:set_bounds(bounds)
        self.bounds = bounds
        self:setpos(self.x, self.y)
    end
    function e:flicker(duration)
        if(not self.flickerer.is_flickering)then
            self.flickerer.duration=duration
            self.flickerer.is_flickering=true
            self.flickerer:flicker()
        end
        return self.flickerer.is_flickering
    end
    function e:draw()
        if(self.flickerer.timer % self.flickerer.slowness == 0)then
            self.anim_obj:draw(self.x,self.y,self.flipx,self.flipy)
        end
        if(self.flickerer.is_flickering) self.flickerer:flicker()        
		if(self.debugbounds) self.bounds:printbounds()
    end
    return e
end

function timer(updatables, step, ticks, max_runs, func)
    local t={}
    t.tick=0
    t.step=step
    t.trigger_tick=ticks
    t.func=func
    t.count=0
    t.max=max_runs
    t.timers=updatables
    function t:update()
        self.tick+=self.step
        if(self.tick >= self.trigger_tick)then
            self.func()
            self.count+=1
            if(self.max>0 and self.count>=self.max and self.timers ~= nil)then
                del(self.timers,self) 
            else
                self.tick=0
            end
        end
    end
    function t:kill()
        del(self.timers, self)
    end
    add(updatables,t) 
    return t
end

function tutils(args)
	local s={}
	s.private={}
	s.private.tick=0
	s.private.blink_speed=1
	s.height=10 
	s.text=args.text or ""
	s._x=args.x or 2
	s._y=args.y or 2
	s._fg=args.fg or 7
	s._bg=args.bg or 2
	s._sh=args.sh or 3 	
	s._bordered=args.bordered or false
	s._shadowed=args.shadowed or false
	s._centerx=args.centerx or false
	s._centery=args.centery or false
	s._blink=args.blink or false
	s._blink_on=args.on_time or 5
	s._blink_off=args.off_time or 5
	function s:draw()
		if self._centerx then self._x =  64-flr((#self.text*4)/2) end
		if self._centery then self._y = 64-(4/2) end
		if self._blink then 
			self.private.tick+=1
			local offtime=self._blink_on+self._blink_off 
			if(self.private.tick>offtime) then self.private.tick=0 end
			local blink_enabled_on = false
			if(self.private.tick<self._blink_on)then
				blink_enabled_on = true
			end
			if(not blink_enabled_on) then
				return
			end
		end
		local yoffset=1
		if self._bordered then 
			yoffset=2
		end
		if self._bordered then
			local x=max(self._x,1)
			local y=max(self._y,1)
			if(self._shadowed)then
				for i=-1, 1 do	
					print(self.text, x+i, self._y+2, self._sh)
				end
			end
			for i=-1, 1 do
				for j=-1, 1 do
					print(self.text, x+i, y+j, self._bg)
				end
			end
		elseif self._shadowed then
			print(self.text, self._x, self._y+1, self._sh)
		end
		print(self.text, self._x, self._y, self._fg)
    end
	return s
end

function collides(ent1, ent2)
    local e1b=ent1.bounds
    local e2b=ent2.bounds
    if  ((e1b.xoff1 <= e2b.xoff2 and e1b.xoff2 >= e2b.xoff1)
    and (e1b.yoff1 <= e2b.yoff2 and e1b.yoff2 >= e2b.yoff1)) then 
        return true
    end
    return false
end
function point_collides(x,y, ent)
    local eb=ent.bounds
    if  ((eb.xoff1 <= x and eb.xoff2 >= x)
    and (eb.yoff1 <= y and eb.yoff2 >= y)) then 
        return true
    end
    return false
end
function circle_explo()
	local ex={}
	ex.circles={}
	function ex:explode(x,y)
		add(self.circles,{x=x,y=y,t=0,s=2})
	end
	function ex:multiexplode(x,y)
		local time=0
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1 }) time-=2
		add(self.circles,{x=x+7,y=y-3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x-7,y=y+3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x+7,y=y+3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x-7,y=y-3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1}) time-=2
	end
	function ex:update()
		for ex in all(self.circles) do
			ex.t+=ex.s
			if ex.t >= 20 then
				del(self.circles, ex)
			end
		end
	end
	function ex:draw()
		for ex in all(self.circles) do
			circ(ex.x,ex.y,ex.t/2,8+ex.t%3)
		end
	end
	return ex
end
--  --<*sff/buttons.lua

local tick_dance=0
local step_dance=0
function dance_bkg(delay,color)
    local sp=delay
    local pat=0b1110010110110101
    tick_dance+=1
    if(tick_dance>=sp)then
        tick_dance=0
        step_dance+=1
        if(step_dance>=16)then step_dance = 0 end
    end
    fillp(bxor(shl(pat,step_dance), shr(pat,16-step_dance)))
    rectfill(0,0,64,64,color)
    rectfill(64,64,128,128,color)
    fillp(bxor(shr(pat,step_dance), shl(pat,16-step_dance)))
    rectfill(64,0,128,64,color)
    rectfill(0,64,64,128,color)
    fillp() 
end
function menu_state()
    local state={}
    local texts={}
	add(texts, tutils({text="platformer hero",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
	add(texts, tutils({text="rombosaur studios",centerx=true,y=99,fg=9,sh=2,shadowed=true}))
	add(texts, tutils({text="ludum dare 41", centerx=true,y=19,fg=9,bg=0,bordered=true,shadowed=false,sh=2}))
	add(texts, tutils({text="jump: 🅾️   move: ⬅️➡️⬆️⬇️",x=12,y=70, fg=0,bg=1,shadowed=true, sh=7}))
	add(texts, tutils({text="press ❎ to start", blink=true, on_time=15, centerx=true,y=80,fg=0,bg=1,shadowed=true, sh=7}))
	add(texts, tutils({text="v0.1", x=106, y=97}))
	local ypos = 111
	add(texts, tutils({text="🅾️             ❎  ", centerx=true, y=ypos, shadowed=true, bordered=true, fg=8, bg=0, sh=2}))
	add(texts, tutils({text="  buttons  ", centerx=true, y=ypos, shadowed=true, fg=7, sh=0}))
    add(texts, tutils({text="  z         x  ", centerx=true, bordered=true, y=ypos+3, fg=8, bg=0}))
    ypos+=10
	add(texts, tutils({text="  remap  ", centerx=true, y=ypos, shadowed=true, fg=7, sh=0}))
	local x1=28 
	local y1=128-19 
	local x2=128-x1-2 
	local y2=128 
	local frbkg=1
	local frfg=6
	state.update=function()
        if(btnp(5)) curstate=game_state(1) 
	end
	cls()
	state.draw=function()
		dance_bkg(10,frbkg)
		rectfill(3,2, 128-4, 104, 7)
		rectfill(2,3, 128-3, 103, 7)
		rectfill(4,3, 128-5, 103, 0)
		rectfill(3,4, 128-4, 102, 0)
		rectfill(5,4, 128-6, 102, frfg)
		rectfill(4,5, 128-5, 101, frfg)
		rectfill(25,97,  101, 111, frbkg)
		rectfill(24,98,  102, 111, frbkg)
		pset(23,104,frbkg)
		pset(103,104,frbkg)
        rectfill(x1,y1-1,  x2,y2+1, 0)
		rectfill(x1-1,y1,  x2+1,y2, 0)
		rectfill(x1,y1,  x2,y2, 6)
		local y=122
		rectfill(75-1,y+1-1, 120+1-8,y+1+1, 0)
		rectfill(121-1-8,y+1-1, 121+1-8,128+1, 0)
		rectfill(75,y+1, 120-8,y+1, 8)
		rectfill(121-8,y+1, 121-8,128, 8)
        for t in all(texts) do
            t:draw()
        end
	end
	return state
end
function cursor(x,y)
    local anim_obj=anim()
    anim_obj:add(16,1,0.01,1,5)
    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1)
    local bounds_obj=bbox(8,8*5, 2, 0, 3, 1)
    e:set_bounds(bounds_obj)
    function e:update() end
    return e
end
function note(x,y, noteid, cursor, preview, lastone, callback_obj)
    local anim_obj=anim()
    local sprite = 1
    if(noteid == 0 or noteid == 1) sprite = 3
    anim_obj:add(sprite,1,0.01,2,2)
    local e=entity(anim_obj)
    e.startx = x
    e.starty = y
    e.sprite = sprite
    e.cursor = cursor
    e:setpos(x,y)
    e:set_anim(1)
    e.flipx = false
    e.flipy = false
    if(noteid == 0) e.flipx = true
    if(noteid == 3) e.flipy = true
    e.active = false 
    e.was_active = false 
    e.status = 0 
    e.preview_fuse = true 
    local bounds_obj=bbox(8*2,8*2)
    e:set_bounds(bounds_obj)
    function e:update()
        if(collides(self, cursor))then
            self.active = true
        else
            self.active = false
        end
    end
    e._draw = e.draw
    e.ctr=0
    e.buttons={0,1,2,3}
    function e:draw()
        if(self.active)then
            self.was_active = true
            if(not preview.do_prev)then
                for b in all(self.buttons) do
                    if(b==noteid) then
                        if( btnp(b) )then
                            sfx(b)
                            pal(2,7)
                            spr(self.sprite, self.x-1, self.y, 2, 2, self.flipx, self.flipy)
                            spr(self.sprite, self.x, self.y-1, 2, 2, self.flipx, self.flipy)
                            spr(self.sprite, self.x, self.y+1, 2, 2, self.flipx, self.flipy)
                            spr(self.sprite, self.x+1, self.y, 2, 2, self.flipx, self.flipy)
                            pal(2,2)
                            if(self.status != -1  and self.status != 1)then
                                self.status = 1 
                            end
                        end 
                    elseif(btnp(b)) then
                        self.status = -1
                        sfx(4)
                    end
                end
            elseif(self.preview_fuse)then
                self.preview_fuse = false
                sfx(noteid)
            end
        elseif(self.was_active and self.status == 0 and not preview.do_prev) then
            self.status = -1
            sfx(4)
        end
        if(self.status == -1 and not preview.do_prev)then
            pal(2,5) pal(9,6)
            spr(self.sprite, self.x, self.y, 2, 2, self.flipx, self.flipy)
            pal(2,2) pal(9,9)
        else
            self:_draw()
        end
        if(not self.active and self.was_active and lastone)then
            callback_obj:done()
        end
    end
    function e:reset()
        self.status = 0
        self.was_active = false
        self.active = false
        self:setpos(self.startx, self.starty)
    end
    return e
end
function staff(enemy, ents_vect, state)
    local s = {}
    s.preview = {}
    s.preview.do_prev = true
    local notes = enemy.notes
    s.total_notes=#notes
    s.enemy = enemy
    s.speed = enemy.speed
    local cursorx = 61
    local cursory = 20
    s.startx = 80
    s.starty = cursory+12
    s.x = s.startx
    s.y = s.starty
    s.cursor = cursor(cursorx, cursory)
    s.missed_cnt = 0
    s.notes_vect = {}
    s.notes_distance_in_px = 22
    s.metronome_ctr = 0
    for i = 1, #notes, 1 do
        local n = notes[i]
        local note = note(s.x, s.y, n, s.cursor, s.preview, (i == #notes) ,s)
        add(ents_vect, note)
        add(s.notes_vect, note)
        s.x += s.notes_distance_in_px
    end
    add(ents_vect, s.cursor)
    function s:draw() end
    function s:update() 
        for n in all(self.notes_vect) do
            n:setx(n.x - self.speed)
        end
        if(self.metronome_ctr % (self.notes_distance_in_px/self.speed) == 0 
            or self.metronome_ctr == 0 ) then 
            sfx(5) 
        end
        self.metronome_ctr+=1
    end
    function s:done()
        if(not self.preview.do_prev)then
            self.missed_cnt = 0
            for n in all(self.notes_vect) do
                if(n.status == -1) self.missed_cnt+=1 
            end
            curstate=state
            local dmg_given = self.total_notes-self.missed_cnt
            local dmg_taken = self.missed_cnt
            state:duel_ended(dmg_taken, dmg_given, self.enemy)
        else
            self.preview.do_prev = false
            for n in all(s.notes_vect) do
                n:reset()
            end
            self.metronome_ctr = 0
        end
    end
    return s
end
function ghero_state(enemy, prev_state)
    local s={}
    local ents={}
    local atention_txt=tutils(
        {text="  atention!!!",
        centerx=true,
        y=88,
        fg=8,
        bg=0,
        bordered=true,
        shadowed=true,
        sh=2,
        blink=true, on_time=15}
    )
    local play_txt=tutils(
        {text="  play!!!",
        centerx=true,
        y=88,
        fg=10,
        bg=0,
        bordered=true,
        shadowed=true,
        sh=2,
        blink=true, on_time=15}
    )
    local staff = staff(enemy, ents, prev_state)
    add(ents, staff)
    s.update=function()
        for u in all(ents) do
            u:update()
        end
    end
    s.draw=function()
        cls()
        camera(0,0)
        fillp(0b0001001001001000)
        rectfill(0,0, 128,60,2)
        fillp(0b1000010000100001)
        rectfill(0,60, 128,128,2)
        fillp()
        rectfill(0,15, 128, 66, 1)
        fillp(0b0101101001011010)
        line(0,13, 128,13, 0)
        rectfill(0, 14, 128, 15, 5)
        rectfill(0, 15, 128, 17, 13)
        rectfill(0, 63, 128, 65, 13)
        rectfill(0, 66, 128, 67, 5)
        line(0,67, 128,67, 0)
        fillp()
        for d in all(ents) do
            d:draw()
        end
        if(staff.preview.do_prev)then
            atention_txt:draw()
        else
            play_txt:draw()
        end
    end
    return s
end
function hero(x,y)
    local anim_obj=anim()
    anim_obj:add(33,2,0.1,1,2)   
    anim_obj:add(65,4,0.3,1,2)  
    anim_obj:add(97,2,0.3,2,1)  
    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1) 
    local bounds_obj=bbox(8,16)
    e:set_bounds(bounds_obj)
    e.walking_speed=1.5
    e.crawling_speed=0.8
    e.speed=e.walking_speed
    e.jump_pwr = 7
    e.jump_tmr = 0 
    e.jump_length = 6 
    e.gravity_accel = 1
    e.crawling = false
    e.score = 0
    e.health = 3
    function e:hurt(dmg)
        self.health -= dmg
    end
    function e:update()
        local height = self.anim_obj.current.h * 8
        local width = self.anim_obj.current.w * 8
        local tile = mget( (self.x+width/2)/8, (self.y+height)/8)
        local grounded = fget(tile, 0)
        if not grounded then
            self.gravity_accel += 0.3
            self:sety(self.y+self.gravity_accel)
            if not self.crawling then
                if(self.jump_tmr <= self.jump_length) then
                    self.jump_tmr += 1
                    self:sety(self.y-self.jump_pwr)
                end
                local collides = fget( mget( (self.x+width/2)/8  , self.y/8),0 ) 
                if(collides) then
                    self.jump_tmr = self.jump_length +1 
                    self.gravity_accel -= 1    
                    local curTileY = self.y     
                    repeat
                        curTileY = curTileY + 8
                        collides = fget( mget( (self.x+width/2)/8  , curTileY/8),0 )     
                    until not collides 
                    self:sety( flr(curTileY/8) * 8 )
                end
                tile = mget( (self.x+width/2)/8, (self.y+height)/8)
                grounded = fget(tile, 0)
                if(grounded)then
                    self.gravity_accel = 1
                    if(self.y+height > flr( (self.y+height)/8)*8 )then
                        self:sety( flr( (self.y+height)/8)*8 - height  )
                    end    
                end
            end
        end
        if(btn(0) or btn(1))then
            local newx = self.x
            local collides
            if(btn(0))then          
                self.flipx=true;
                newx=self.x-self.speed
                collides =             fget( mget( (self.x-1)/8, self.y/8),0 )               
                collides = collides or fget( mget( (self.x-1)/8, (self.y+height/2)/8),0 )    
                collides = collides or fget( mget( (self.x-1)/8, (self.y+height-1)/8),0 )    
            elseif(btn(1))then      
                self.flipx=false;
                newx=self.x+self.speed
                collides =             fget( mget( (self.x+width)/8, self.y/8),0 )               
                collides = collides or fget( mget( (self.x+width)/8, (self.y+height/2)/8),0 )    
                collides = collides or fget( mget( (self.x+width)/8, (self.y+height-1)/8),0 )    
            end
            if not collides then
                self:set_anim(2)
                self:setx(newx)
            end
        else
            self:set_anim(1) 
        end
        if(btn(2))then      
        end
        if(btn(3) and grounded )then  
            if(not self.crawling) then
                self:sety(self.y+8)
                if(not self.flipx)then
                    self:setx(self.x-8)
                end
            end
            self.crawling = true
            self:set_anim(3) 
            self.speed = self.crawling_speed
        elseif(self.crawling) then
            local can_standup
            local upwards_tile_y = (self.y/8) - 1
            if(self.flipx)then
                can_standup = not fget(mget(    (self.x+1)/8, upwards_tile_y ),0 )           
            else
                can_standup = not fget(mget(    (self.x+width-1)/8, upwards_tile_y), 0) 
            end
            if(can_standup)then
                self.crawling = false
                self:sety(self.y-8)
                if(not self.flipx)then
                    self:setx(self.x+8)
                end
                self.speed = self.walking_speed
            else
                self:set_anim(3) 
            end
        end
        if(btnp(4))then 
        end
        if(btnp(5) and grounded and not self.crawling)then 
            self.jump_tmr = 0
            self:sety(self.y-1) 
        end
    end
    e._draw = e.draw
    function e:draw()
        self:_draw()
        for l = 1, self.health, 1 do
            pset(
                self.x-1 +(2*l),
                self.y - 2,
                8)
        end
    end
    return e
end
function ruby(x,y,hero)
    local anim_obj=anim()
    anim_obj:add(5,8,0.3,1,1)
    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1)
    e.alive = true
    e.points = 10
    local bounds_obj=bbox(8,8)
    e:set_bounds(bounds_obj)
    function e:update()
        if(collides(self, hero) and self.alive)then
            self.alive=false
            hero.score+=self.points
        end
    end
    return e
end
function exitdoor(x,y, hero, game_state)
    local anim_obj=anim()
    anim_obj:add(25,1,0.01,1,2)
    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1)
    local bounds_obj=bbox(8,8)
    e:set_bounds(bounds_obj)
    function e:update()
        if(collides(hero, self))then
            game_state:next_lvl()
        end
    end
    return e
end
function enemy(x,y, hero, state, notes, cursor_speed, first_spr)
    local anim_obj=anim()
    anim_obj:add(first_spr,2,0.2,1,2) 
    anim_obj:add(24,1,0.01,1,2) 
    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1)
    e.fuse = true
    e.notes = notes
    e.health = #notes 
    e.speed = cursor_speed 
    local bounds_obj=bbox(8,8)
    e:set_bounds(bounds_obj)
    function e:hurt(dmg)
        self.health -= dmg
        for i=1, dmg, 1 do
            exp:explode(self.x+i*2, self.y-2-(i/2) )
        end
    end
    function e:update()
        if(self.health <= 0)then
            e:set_anim(2)
            return
        end
        if(collides(hero, self))then
            if(self.fuse)then
                self.fuse = false
                curstate=ghero_state( self, state)
            end
        else
            self.fuse = true
        end
    end
    e._draw = e.draw
    function e:draw()
        self:_draw()
        for l = 1, self.health, 1 do
            pset(
                self.x-1 +(2*l),
                self.y - 2,
                8)
        end
    end
    return e
end
function spawn_hero(startx, starty, ents_table)
    local hero_spawn = 39 
    local _hero = {}
    local row=starty
    while( not fget(mget(startx, row), 7) ) do
        local col = startx
        while ( not fget(mget(col, row), 7) ) do
            local curtile = mget(col, row)
            if(curtile == hero_spawn)then
               _hero = hero(col*8,(row-1)*8)
               add(ents_table, _hero)
               return _hero
            end
            col += 1 
        end
        row+=1 
    end
end
function parse_map(startx, starty, _hero, game_state, rubies_table, ents_table)
    local enemy_types = {
        { sprite=21, cant_notes=6, cursor_speed=1.5 },
        { sprite=53, cant_notes=4, cursor_speed=2.5 },
        { sprite=55, cant_notes=7, cursor_speed=2 },
        { sprite=85, cant_notes=12, cursor_speed=2.1 },
        { sprite=87, cant_notes=3, cursor_speed=3 }
    }
    local collectibles_sprs = { 
        {sprite=5}, 
        {sprite=25} 
    }
    local row=starty
    local col=startx
    while( not fget(mget(startx, row), 7) ) do
        col = startx
        while ( not fget(mget(col, row), 7) ) do
            local curtile = mget(col, row)
            for e in all(enemy_types) do
                if(curtile == e.sprite)then
                    mset(col, row, 0) 
                    local notes = {}
                    for i=1, e.cant_notes do
                        notes[i] = flr(rnd(4))
                    end
                    local ent = enemy(col*8,row*8, _hero, game_state, notes, e.cursor_speed, e.sprite)
                    add( ents_table, ent)
                end
            end
            for c in all(collectibles_sprs) do
                if(curtile == c.sprite)then
                    mset(col, row, 0) 
                    if(c.sprite == 5)then 
                        local r = ruby(col*8, row*8, _hero)
                        add(rubies_table, r)
                        add(ents_table, r)
                    elseif(c.sprite == 25)then 
                        add(ents_table, exitdoor(col*8, row*8, _hero, game_state))
                    end
                end
            end
            col += 1 
        end
        row+=1 
    end
    return {width=col+1, height=row+1}
end
function game_state(level)
    local s={}
    local camx = 0
    local camy = 0
    local camspeed = 1.2
    local ents={}
    local rubies={}
    local seconds=0
    local intro_timeout=0
    local level_txt=tutils(
        {text="level  ",
        centerx=true,
        centery=true,
        fg=8,
        bg=0,
        bordered=true,
        shadowed=true,
        sh=2})
    local points_dimmed=tutils({text="00000", fg=5, bordered=false, x=107, y=2})
    local points=tutils({text="0", fg=7, bordered=false, x=123, y=2})
    local first_digit=points._x
    s.levels={
        {
            id=1,
            startx=1, 
            starty=1,
            mapx=0, 
            mapy=0, 
            time=0 
        },{
            id=2,
            startx=27,
            starty=1,
            mapx=26*8,  
            mapy=0,     
            time=0 
        },{
            id=3,
            startx=1,
            starty=10,
            mapx=(1-1)*8, 
            mapy=(10-1)*8, 
            time=0 
        }
    }
    s.curlevel = {}
    for l in all(s.levels) do
        if(level == l.id)then
            s.curlevel = l
        end
    end
    s.hero = spawn_hero(s.curlevel.startx, s.curlevel.starty, ents)
    local msize=parse_map(s.curlevel.startx, s.curlevel.starty,  s.hero, s, rubies, ents)
    camx=s.hero.x-64
    camy=s.hero.y-64
    local mstartx = camx
    local mstarty = camy
    s.update=function()
        if(intro_timeout < 50)then
            intro_timeout+=1
            return
        end
        for u in all(ents) do
            u:update()
        end
        for r in all(rubies) do
            if(not r.alive) then
                del(ents, r)
                del(rubies, r)
            end
        end
        local delta = abs(camx - s.hero.x)
        if (delta > 74) then
            camx += camspeed
        elseif (delta < 54) then
            camx -= camspeed
        end
        delta = abs(camy - s.hero.y)
        if (delta > 74) then
            camy += camspeed
        elseif (delta < 54) then
            camy -= camspeed
        end
    end
    s.draw=function()
        cls()
        if(intro_timeout < 50)then
            camera(0,0)
            rectfill(0,0,128,128,2)
            level_txt.text = "level "..level
            level_txt:draw()
            return
        end
        camera(camx, camy)
        map(s.curlevel.startx-1, s.curlevel.starty-1, s.curlevel.mapx, s.curlevel.mapy, msize.width, msize.height)
        for d in all(ents) do
            d:draw()
        end
        camera(0,0)
        rectfill(0,0, 127,8, 6)
        points_dimmed:draw()
        points.text=s.hero.score
        if(s.hero.score > 0)then
            if(s.hero.score > 9999)then 
                points._x=first_digit - 4*4
                points_dimmed.text=""
            elseif(s.hero.score > 999)then 
                points._x=first_digit - 3*4
                points_dimmed.text="0"
            elseif(s.hero.score > 99)then 
                points._x=first_digit - 2*4
                points_dimmed.text="00"
            elseif(s.hero.score > 9)then 
                points._x=first_digit - 4
                points_dimmed.text="000"
            end
        end
        points:draw()
        camera(camx, camy)
    end
    function s:duel_ended(dmg_taken, dmg_given, enemy)
        self.hero:hurt(dmg_taken)
        enemy:hurt(dmg_given)
    end
    function s:next_lvl()
        curstate=game_state(level+1)
    end
    return s
end

function gameover_state()
    local s={}
    local texts={}
    local frbkg=8
    local frfg=6
    music(-1)
    sfx(-1)
    local ty=15
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         " ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="press ❎ to restart", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7}))
    s.update=function()
        if(btnp(5)) curstate=game_state() 
    end
    cls()
    s.draw=function()
        dance_bkg(10,frbkg)
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
        for t in all(texts) do
            t:draw()
        end
    end
    return s
end
function win_state()
    local s={}
    local texts={}
    local frbkg=11
    local frfg=6
    music(-1)
    sfx(-1)
    local ty=15
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         " ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="press ❎ to restart", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7}))
    s.update=function()
        if(btnp(5)) curstate=menu_state() 
    end
    cls()
    s.draw=function()
        dance_bkg(10,frbkg)
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
        for t in all(texts) do
            t:draw()
        end
    end
    return s
end
--------------------------- End Imports

-- To enable MOUSE support uncomment ALL of the following commented lines:
-- poke(0x5F2D, 1) -- enables mouse support
function _init()
    curstate=menu_state()
    exp = circle_explo()
end

function _update()
    -- mouse utility global variables
    -- mousex=stat(32)
    -- mousey=stat(33)
    -- lclick=stat(34)==1
    -- rclick=stat(34)==2
    -- mclick=stat(34)==4
    curstate.update()
    exp:update()
end

function _draw()
    curstate.draw()
    exp:draw()
    -- pset(mousex,mousey, 12) -- draw your pointer here
end
__gfx__
00000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333333333333333333333333
00000000000000299200000000000000020000000000000000000000000000000000000000000000000000000000000000000000533333333333333333333333
00000000000002999920000000000000022000000000000000000000000000000000000000000000000000000000000000000000455553333333533354553544
00000000000029999992000000000000029200000000a0000000a000000020000000a0000000a0000000a0000000a0000000a000445544544554455444455444
000000000002999999992000000000000299200000027a0000027a0000002000000a7200000a7200000a72000000a00000027a00444444444444554444444444
0000000000299999999992000000000002999200002777a000027a0000002000000a720000a77720000a72000000a00000027a00444454444444455444444444
0000000002222229922222200022222222999920000279000002790000002000000a720000097200000a72000000a00000027900444444444444444444444454
00000000000000299200000002999999999999920000900000009000000020000000900000009000000090000000a00000009000444444444444444444444444
8888888800000029920000000299999999999992000ddd00000000000bb333b000000000444444440dddddd00dddddd08888888a333333333333333344444454
88888888000000299200000000222222229999200022fdd0000ddd003bbb33bb0000000049944994d666666dd6dd666d8888888a333333333353333345444444
0888888000000029920000000000000002999200022fffdd0022fdd03bb333bb0000000049944994d6666d6dddd6666d088888a0333355533545335304445444
008888000000002992000000000000000299200002f1f1fd022fffdd333333330005600049944994d66ddd6dd666666d00888a00333345444444554304455444
0008800000000029920000000000000002920000002fffd002f1f1fd33333b330005600049944994dd6dd66dd666666d0008a000335544544444444504455444
00088000000000299200000000000000022000000222fdd002222ddd3333bbb30566666049944444dd66666dd666666d0008a000535444444455444504444444
000880000000000220000000000000000200000002222ddd222ddd2d3333333300056000444444a4d6666dddd66dd66d0008a000454445444445444444554444
0008800000000000000000000000000000000000222ddd2d2ddddd2d03b3333000056000499444440dddddd00dddddd00008a000444444444444444444554444
0008800000004440000044400041f100004444002ddddd2d2ddddd2d000000000005600049944994033333300dddddd00008a000444444444444444444444444
0008800000041f1000041f10004fff000041f1002ddddd2df02ddddf0000000000566600499449943b333333d666666d0008a000444444444445444444444544
000880000004fff00004fff0004fff00004fff00f02ddddf002dddd000000000056666604994499433333333d666666d0008a000454444444444444444444444
000880000000ff00000122000112211001122110002dddd0002dddd000777700056776604994499433333333dd66666d0008a000444445444444444444554444
0008800000012200001222201022220110222201002222d0002222d007787870056666604444444433bbb333dd66666d0008a000444444444444444444544444
0008800000122220001222201022220110222201002222d0002222d0078787700567676005555550333bb333d6666ddd0008a000444444444544444444444554
0008800000122220001222201022220110222201002222d0002222d078787877056666605555555533333333d6666ddd0008a000444444444544444444444554
00088000010222200012222000444400004444000555055505550555777777770566666055555555033333300dddddd00008a000444444444444445444444444
0008800001022221000222200444444004444440000000000000000000000000000000000000500000005000011111100008a000000000ffffffffffff000000
0008800001022220000444400440044004400440000000000000000000000000000000000000500000050000156666510008a0000000ffffffffffffffff0000
0008800000044440000400400400004004000040000000000000000000000000000000000000050000050000155665610008a000000ffffffffffffffffff000
0008800000040040000400400040040000400400000000000099990000000000004444000000550000055000555556610008a00000ffffffffffffffffffff00
000880000004004000400040005005000050050000999900044444900044440000744700000500000000500051515661000a80000fff55ffffffffffff55fff0
000880000040004000400400000000000000000004444490446666990074470000444400005500000000050051155561000a80000ff5555ffffffffff5555ff0
000880000400040004000400000000000000000044666699466666690044440001444410005000000000050051115551000a80000ff9955555ffff5555599ff0
000880000550055005500550000000000000000046666669461661690144441011111111005500000000500005555110000a80000fff777955ffff559777fff0
000880000000444000004440000044400000444044166149446666491111111111111111000000000000000045444444000a80000fff707955ffff559707fff0
000880000004f1f00004f1f00004f1f000041f1004666640046666401111111111111111000000000000000044444454000a800000ff777995ffff599777ff00
000880000004fff00004fff00004fff00004fff049444449494444490111111010111101000000000000000044454440000a800000ff99999ffffff99999ff00
000880000000ff000000ff000000ff000000ff0044999449449994490411114040111104000000000000000044455440000a800000fff99fff9ff9fff99fff00
000880000001220000002200000122000001220064449446644494460011110000111100000000000000000044455440000a800000ffffffff9ff9ffffffff00
0008800000012220000212200001222000122220444994494449944900dddd0000dddd00000000000000000044444440000a800000ffffffffffffffffffff00
0008800000012220000212210001222001022221449944994499449900d00d0000d00d00000000000000000044445544000a800000ffffff9ffffff9ffffff00
0008800000021220000221100002122001022221049554900495549000d00d0000d00d00000000000000000044445544000a800000ffffff99ffff99ffffff00
000880000002122000122220000212200102222000066600000000000000000000000000000000000000000000000000000a800000ffffffff9999ffffffff00
000880000002212000022220000221200002222000554660000666000000000000000000000000000000000000000000000a8000000ffffffffffffffffff000
000880000004444000044440000444400004444005544466005546600000000000000000000000000000000000000000000a8000000ffffffffffffffffff000
000880000004440000004440000444000004444005484846055444660000000000ffff00000000000000000000000000000a80000000fffff999999fffff0000
0088880000044000000040040004400000040040005444600548484600ffff00007ff700000000000000000000000000008aaa0000000fff9ffffff9fff00000
08888880000040000000400400004000004000400555466005555666007ff70000ffff00000000000000000000000000088888a0000000ffffffffffff000000
8888888800044400000400400004440004000040055556665556665600ffff0008ffff800000000000000000000000008888888a0000000ffff99ffff0000000
8888888800550550000550550055055005500055555666565666665608ffff80888888880000000000000000000000008888888a0000000ffff9fffff0000000
00000000000000000000000000000000000000005666665656666656888888888888888800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005666665640566664888888888888888800000000000000000000000000000000000000000000000000000000
00000000000000000044400000000000004440004056666400566660088888808088880800000000000000000000000000000000000000000000000000000000
00000000000042222241f00000004222221f100000566660005666600f8888f0f088880f00000000000000000000000000000000000000000000000000000000
0000000000044222124ff0000004422212fff0000055556000555560008888000088880000000000000000000000000000000000000000000000000000000000
00000000000444001100000000044000110000000055556000555560004444000044440000000000000000000000000000000000000000000000000000000000
00000000540440401100000054440401001000000055556000555560004004000040040000000000000000000000000000000000000000000000000000000000
00000000504404401111100050005441110111000555055505550555004004000040040000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000001010100000000000000010002010100010101000000000000000000020101000101010000000000000000000000810000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b0000393a1b1a1a2b2b1b1b1b1b1b1b000000000000000000003b000000192b000000000000000000001b2b1b2b0000000055003b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b0000393a00001b1a1b1b1b1b1b2b1a050000000000000000003b000000291b000000000505000000001b2b2b1b0000000000053b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2700393a00003a000000000000001a1a0000000000003500053b0000001b1a00000000172a1a000000000500000000000d0e0f3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2b1b1a1a1b1b2b2b2b1b2b0000002b1a00000000000000001a3b00001a00000000002a0000001b2b1a2b2b1b1b1a1b2a17172a3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2b2b1b1b1b1a1a1b2b1b1b0000001a2b0000000055001b1a1b3b00000000000000000000000000000000001a1a1a00000000003b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b00000000000000000000000000001b1a0037570000001a1a1a3b0000000000001a000000000000000000001a1a1a00003700003b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b00190000000000000500000000050000000000002b1a1a1b2b3b1b000000001a2b1a00000057000000000000000000000000053b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b00290000000000001d0e0e0e0e0e0e0e0e0e0e1a1a1a1b1b1a3b00000027002b1b1a1b000000000000001a1a1b1a1a1a1b1b1a3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b0000000000000000001b2e2f1b1b1b1b1b1b2e2d2e2d2f1b1b1b1b1b0000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b0000000000000000001b2f2e1b000000001b1b1b1b1b1b1b0000001b1b1b1b0000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b0000000000000000001b2e2e1b0000000000000000000000002700000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b1b1b00000000001b1b1b1b1b1b000000001b1b1b1b1b1b1b1b1b1b1b1b1b1b0000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2e1b0000000000000000000000000000001b000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2f1b00000000000000001b1b1b1b1b1b1b1b000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2e1b001b1b1b000000001b2f2f2e2f2f2e2f000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b4b00001f2f1b1b1b1b1b1b2e2e2f001f4b00000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b4b00000000000000000000000000001f4b00000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b4b00000000000000000000000000001f4b00000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b4b00000000000000000000001900001f4b00000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b4b00000000000000000000002900001f4b00000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2e0d0f0f0f0f0f0f0f0f0f0f0f0f0f2f4b00000000000000000000000000000000000000000000000000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400002905029050290502905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002b0502b0502b0502b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003005030050300503005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002e0502e0502e0502e05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000246500f350246500f35000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000735000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
