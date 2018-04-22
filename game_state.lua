function hero(x,y, game_state)
    local anim_obj=anim()
    anim_obj:add(33,2,0.1,1,2)   -- idle
    anim_obj:add(65,4,0.3,1,2)  -- walk
    anim_obj:add(97,2,0.3,2,1)  -- crawl

    local e=entity(anim_obj)
   
    e.spawnx=x
    e.spawny=y
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
        
        if not grounded then
            -- apply gravity
            self.gravity_accel += 0.3
            self:sety(self.y+self.gravity_accel)
            if not self.crawling then
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

        if(self.health <= 0)then
            self.health = 3
            self:setpos(self.spawnx, self.spawny)
            camx=self.spawnx-64
            camy=self.spawny-64
            curstate=message_state("you've got schooled, son!", game_state, 1)
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

function exitdoor(x,y, hero, game_state)
    local anim_obj=anim()
    anim_obj:add(25,1,0.01,1,2)

    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1)

    local bounds_obj=bbox(8,8)
    e:set_bounds(bounds_obj)
    -- e.debugbounds=true

    function e:update()
        if(collides(hero, self))then
            -- TODO check conditions
            game_state:next_lvl()
        end
    end

    return e
end

-- all enemies must have only 2 spr in animation. they all share the death anim
function enemy(x,y, hero, state, notes, cursor_speed, first_spr)
    local anim_obj=anim()
    anim_obj:add(first_spr,2,0.2,1,2) -- idle
    anim_obj:add(24,1,0.01,1,2) -- death

    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1)
    e.fuse = true
    e.notes = notes
    e.health = #notes -- If you hit all notes, the enemy dies
    e.speed = cursor_speed -- speed of notes when in ghero mode

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

function spawn_hero(startx, starty, ents_table, game_state)
    local hero_spawn = 39 -- spawn tile
    local _hero = {}

    -- while I still have rows to parse
    local row=starty
    while( not fget(mget(startx, row), 7) ) do
        local col = startx

        -- while I still have columns to parse
        while ( not fget(mget(col, row), 7) ) do
            local curtile = mget(col, row)

            if(curtile == hero_spawn)then
               _hero = hero(col*8,(row-1)*8, game_state)

               add(ents_table, _hero)
               return _hero
            end

            col += 1 -- go to next column
        end

        row+=1 -- go to next row
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
        {sprite=5}, -- ruby
        {sprite=25} -- door
    }

    -- while I still have rows to parse
    local row=starty
    local col=startx
    while( not fget(mget(startx, row), 7) ) do
        col = startx

        -- while I still have columns to parse
        while ( not fget(mget(col, row), 7) ) do
            local curtile = mget(col, row)

            -- parse enemies
            for e in all(enemy_types) do
                if(curtile == e.sprite)then
                    -- delete tile
                    mset(col, row, 0) -- blank sprite

                    -- add object
                    local notes = {}
                    for i=1, e.cant_notes do
                        notes[i] = flr(rnd(4))
                    end

                    local ent = enemy(col*8,row*8, _hero, game_state, notes, e.cursor_speed, e.sprite)
                    add( ents_table, ent)
                end
            end

            -- parse collectibles
            for c in all(collectibles_sprs) do
                if(curtile == c.sprite)then
                    -- delete tile
                    mset(col, row, 0) -- blank sprite

                    -- add obj
                    if(c.sprite == 5)then -- rubies
                        local r = ruby(col*8, row*8, _hero)
                        add(rubies_table, r)
                        add(ents_table, r)
                    elseif(c.sprite == 25)then -- exit door
                        add(ents_table, exitdoor(col*8, row*8, _hero, game_state))
                    end
                end
            end

            col += 1 -- go to next column
        end

        row+=1 -- go to next row
    end

    return {width=col+2 -startx , height=row+2 -starty}
end

function game_state(level)
    local s={}
    camx = 0
    camy = 0
    local camspeed = 1.2
    local ents={}
    local rubies={}
    local seconds=0
    local intro_timeout=0

    -- hud shiet
    local level_txt=tutils(
        {text="level  ",
        centerx=true,
        centery=true,
        fg=9,
        bg=0,
        bordered=true,
        shadowed=true,
        sh=1})
    local points_dimmed=tutils({text="00000", fg=5, bordered=false, x=107, y=2})
    local points=tutils({text="0", fg=7, bordered=false, x=123, y=2})
    local seconds_txt=tutils({text="time ", fg=12, bordered=false, x=2, y=2})
    local first_digit=points._x
    -- end hud

    -- startx and starty are used by the map parser algorithm. It's 1x1px away from 0,0
    s.levels={
        {
            id=1,
            startx=1, 
            starty=1,
            mapx=0, -- (startx-1)*8,
            mapy=0, -- (starty-1)*8,
            time=20 -- time to finish the level
        },{
            id=2,
            startx=27,
            starty=1,
            mapx=26*8,  -- (startx-1)*8,
            mapy=0,     -- (starty-1)*8,
            time=20     -- time to finish the level
        },{
            id=3,
            startx=1,
            starty=10,
            mapx=(1-1)*8,   -- (startx-1)*8,
            mapy=(10-1)*8,  -- (starty-1)*8,
            time=60         -- time to finish the level
        }
    }
    
    -- get level metadata
    s.curlevel = {}
    for l in all(s.levels) do
        if(level == l.id)then
            -- parse this level
            s.curlevel = l
            seconds = s.curlevel.time
        end
    end

    -- spawn hero and parse the map
    s.hero = spawn_hero(s.curlevel.startx, s.curlevel.starty, ents, s)
    local msize=parse_map(s.curlevel.startx, s.curlevel.starty,  s.hero, s, rubies, ents)

    -- camera and map positioning stuff
    camx=s.hero.x-64
    camy=s.hero.y-64
    local mstartx = camx
    local mstarty = camy


    s.update=function()
        -- show the "level x" text
        if(intro_timeout < 50)then
            intro_timeout+=1
            return
        end
        -- ------------------
        -- ------------------
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

        seconds -=1/60 -- decrease 1 per second (asuming 60fps)
    end

    s.draw=function()
        cls()

        if(intro_timeout < 50)then
            camera(0,0)
            fillp(0b0001001001001000)
            rectfill(0,0,128,128,1)
            level_txt.text = "level "..level
            level_txt:draw()
            fillp()
            return
        end

        -- throw a baground for the "space" out of the map
        camera(0,0)
        fillp(0b0001001001001000)
        rectfill(0,0,128,128,9)
        fillp()

        camera(camx, camy)
        -- black map background
        rectfill(s.curlevel.mapx, s.curlevel.mapy, s.curlevel.mapx+ (msize.width*8), s.curlevel.mapy+(msize.height*8),0)

        -- render level
        map(s.curlevel.startx-1, s.curlevel.starty-1, s.curlevel.mapx, s.curlevel.mapy, msize.width, msize.height)

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

        seconds_txt.text = "time "..flr(seconds)
        seconds_txt:draw()

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
