function hero(x,y)
    local anim_obj=anim()
    anim_obj:add(33,2,0.1,1,2)   -- idle
    anim_obj:add(65,4,0.3,1,2)  -- walk
    anim_obj:add(97,2,0.3,2,1)  -- crawl

    local e=entity(anim_obj)
   
    e:setpos(x,y)
    e:set_anim(1) 

    local bounds_obj=bbox(8,16)
    e:set_bounds(bounds_obj)
    -- e.debugbounds=true
    
    e.walking_speed=1.5
    e.crawling_speed=0.8
    e.speed=e.walking_speed
    
    e.jump_pwr = 7
    e.jump_tmr = 0 
    e.jump_length = 6 -- jump power duration
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
        
        if not grounded and not self.crawling then
            -- apply gravity
            self.gravity_accel += 0.3
            self:sety(self.y+self.gravity_accel)

            -- retain jumping
            if(self.jump_tmr <= self.jump_length) then
                self.jump_tmr += 1
                self:sety(self.y-self.jump_pwr)
            end

            -- ******************************************** --
            -- avoid jump into a collidable tile vertically
            -- ******************************************** --
            local collides = fget( mget( (self.x+width/2)/8  , self.y/8),0 ) -- center
            if(collides) then
                self.jump_tmr = self.jump_length +1 -- you collided vertically, stop going up
                self.gravity_accel -= 1    -- slow down gravity acceleration to accentuate the hit
                local curTileY = self.y     -- head y
                
                -- start going down until the first non collidable tile
                repeat
                    curTileY = curTileY + 8
                    collides = fget( mget( (self.x+width/2)/8  , curTileY/8),0 )     -- center
                until not collides 

                self:sety( flr(curTileY/8) * 8 )
            end

            -- ************************************************** --
            -- avoid goind down into a collidable tile vertically
            -- ************************************************** --
            tile = mget( (self.x+width/2)/8, (self.y+height)/8)
            grounded = fget(tile, 0)
            if(grounded)then
                self.gravity_accel = 1
                if(self.y+height > flr( (self.y+height)/8)*8 )then
                    self:sety( flr( (self.y+height)/8)*8 - height  )
                end    
            end
        end
        
        if(btn(0) or btn(1))then
            local newx = self.x
            local collides

            if(btn(0))then          -- left
                self.flipx=true;
                newx=self.x-self.speed

                collides =             fget( mget( (self.x-1)/8, self.y/8),0 )               -- head
                collides = collides or fget( mget( (self.x-1)/8, (self.y+height/2)/8),0 )    -- torso
                collides = collides or fget( mget( (self.x-1)/8, (self.y+height-1)/8),0 )    -- feet
            elseif(btn(1))then      -- right
                self.flipx=false;
                newx=self.x+self.speed

                collides =             fget( mget( (self.x+width)/8, self.y/8),0 )               -- head
                collides = collides or fget( mget( (self.x+width)/8, (self.y+height/2)/8),0 )    -- torso
                collides = collides or fget( mget( (self.x+width)/8, (self.y+height-1)/8),0 )    -- feet
            end

            -- collide horizontally with tiles
            if not collides then
                self:set_anim(2)
                self:setx(newx)
            end
        else
            self:set_anim(1) -- idle
        end
        
        if(btn(2))then      -- up
        end

        if(btn(3) and grounded )then  -- down
            if(not self.crawling) then
                self:sety(self.y+8)
                if(not self.flipx)then
                    self:setx(self.x-8)
                end
            end

            self.crawling = true
            self:set_anim(3) -- crawl
            self.speed = self.crawling_speed
        elseif(self.crawling) then
            -- check if you can stand up or not (you cant if you're under something)
            local can_standup
            local upwards_tile_y = (self.y/8) - 1
            if(self.flipx)then
                can_standup = not fget(mget(    (self.x+1)/8, upwards_tile_y ),0 )           -- left
            else
                can_standup = not fget(mget(    (self.x+width-1)/8, upwards_tile_y), 0) -- right
            end

            if(can_standup)then
                self.crawling = false
                self:sety(self.y-8)
                if(not self.flipx)then
                    self:setx(self.x+8)
                end
                self.speed = self.walking_speed
            else
                self:set_anim(3) -- crawl
            end
        end

        
        
        if(btnp(4))then -- "O"
            
        end
        
        if(btnp(5) and grounded and not self.crawling)then -- "X"
            self.jump_tmr = 0
            self:sety(self.y-1) -- just enough to make the grounded flag false
        end
    end

    e._draw = e.draw
    function e:draw()
        self:_draw()

        -- draw health
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
    -- e.debugbounds=true

    function e:update()
        if(collides(self, hero) and self.alive)then
            self.alive=false
            hero.score+=self.points
            -- todo: cool animation
        end
    end

    return e
end

function enemy(x,y, hero, state, notes,         cursor_speed, ide_anim, dead_anim)
    local anim_obj=anim()
    anim_obj:add(21,2,0.2,1,2) -- idle
    anim_obj:add(24,1,0.01,1,2) -- death

    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1)
    e.fuse = true
    e.notes = notes
    e.health = #notes -- If you hit all notes, the enemy dies
    e.speed = 1 -- speed of notes when in ghero mode

    local bounds_obj=bbox(8,8)
    e:set_bounds(bounds_obj)
    -- e.debugbounds=true

    function e:hurt(dmg)
        self.health -= dmg
        for i=1, dmg, 1 do
            exp:explode(self.x+i*2, self.y-2-(i/2) )
        end
    end

    function e:update()
        if(self.health <= 0)then
            -- dead
            e:set_anim(2)
            return
        end

        if(collides(hero, self))then
            if(self.fuse)then
                self.fuse = false
                curstate=ghero_state( self, state)
                --todo analizar como te fue y restarle una vida al enemy, matarlo o perder vida.
            end
        else
            self.fuse = true
        end
    end

    e._draw = e.draw
    function e:draw()
        self:_draw()

        -- draw health
        for l = 1, self.health, 1 do
            pset(
                self.x-1 +(2*l),
                self.y - 2,
                8)
        end
    end

    return e
end


function game_state()
    local s={}
    local camx = 0
    local camy = 0
    local camspeed = 1.2
    local ents={}
    local rubies={}

    -- hud shiet
    local points_dimmed=tutils({text="00000", fg=5, bordered=false, x=107, y=2})
    local points=tutils({text="0", fg=7, bordered=false, x=123, y=2})
    local first_digit=points._x
    -- hud

    s.hero = hero(20,48)
    local r = ruby(88, 7*8, s.hero)
    local en1 = enemy(12*8, 6*8, s.hero, s, {3,1,0,2,1})
    
    add(rubies, r)
    add(ents, r)
    add(ents, s.hero)
    add(ents, en1)

    local e2 = enemy(21*8, 3*8, s.hero, s, {1,2,3})
    e2.speed = 2
    add(ents, e2)




    s.update=function()
        for u in all(ents) do
            u:update()
        end

        for r in all(rubies) do
            if(not r.alive) then
                del(ents, r)
                del(rubies, r)
            end
        end
        
        -- camera smoothing
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
        camera(camx, camy)
        map(0,0,0,0)
        for d in all(ents) do
            d:draw()
        end

        -- *** --
        -- hud
        -- *** --
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


    return s
end
