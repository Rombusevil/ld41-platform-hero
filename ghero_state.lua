local _global={}
_global.notes_distance_in_px = 22

function cursor(x,y, speed, callback_obj)
    local anim_obj=anim()
    anim_obj:add(16,1,0.01,1,5)

    local e=entity(anim_obj)
    e.startx = x
    e:setpos(x,y)
    e:set_anim(1)

    local bounds_obj=bbox(8,8*5, 2, 0, 3, 1)
    e:set_bounds(bounds_obj)
    --e.debugbounds=true

    e.speed = speed
    e.running = false
    e.metronome_ctr=0

    function e:relaunch()
        self:setx(self.startx)
        self.metronome_ctr = 0
        self.running = true
        printh("metronome_ctr 0")
    end

    function e:update()
        if(self.running)then
            self:setx(self.x + self.speed)

            if(self.metronome_ctr % (_global.notes_distance_in_px/self.speed) == 0 
                or self.metronome_ctr == 0 ) then 
                sfx(5) --metronome 22 es la distancia en px de las notas
            end

            self.metronome_ctr+=1
            printh("metronome_ctr ++ "..self.metronome_ctr)

            -- todo definir limites de corrida, y cuando termina marca beredicto
            if(self.x > 128)then
                self.running = false
            end
        else
            -- notify upwards that the cursor has finished
            callback_obj:done()
        end
    end

    return e
end

-- 0 left, 1 right, 2 up, 3 down, 
function note(x,y, noteid, cursor, preview)
    local anim_obj=anim()
    
    local sprite = 1
    if(noteid == 0 or noteid == 1) sprite = 3

    anim_obj:add(sprite,1,0.01,2,2)

    local e=entity(anim_obj)
    e.sprite = sprite
    e.cursor = cursor
    e:setpos(x,y)
    e:set_anim(1)
    e.flipx = false
    e.flipy = false
    if(noteid == 0) e.flipx = true
    if(noteid == 3) e.flipy = true

    e.active = false -- it turns active when colliding with cursor
    e.was_active = false -- this flag turns on when the note gets active. if the player doesn't do anything, then with this flag I can set the MISSED state
    e.status = 0 --  0 is when user never does anything, 1 when ok, and -1 when fail
    e.preview_fuse = true -- fuse to play the preview sound

    -- todo add sound according to noteid

    local bounds_obj=bbox(8*2,8*2)
    e:set_bounds(bounds_obj)
    --e.debugbounds=true

    function e:update()
        -- the note is active when colliding with cursor
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
                -- check for the keys the user is pressing
                for b in all(self.buttons) do
                    if(b==noteid) then
                        -- user pressed this note's key
                        if( btnp(b) )then
                            sfx(b)
                            pal(2,7)
                            spr(self.sprite, self.x-1, self.y, 2, 2, self.flipx, self.flipy)
                            spr(self.sprite, self.x, self.y-1, 2, 2, self.flipx, self.flipy)
            
                            spr(self.sprite, self.x, self.y+1, 2, 2, self.flipx, self.flipy)
                            spr(self.sprite, self.x+1, self.y, 2, 2, self.flipx, self.flipy)
                            pal(2,2)
            
                            if(self.status != -1  and self.status != 1)then
                                self.status = 1 --OK
                            end
                        end 
                    elseif(btnp(b)) then
                        -- user pressed any other key, so he made a mistake
                        self.status = -1
                        sfx(4)
                    end
                end
            elseif(self.preview_fuse)then
                self.preview_fuse = false
                sfx(noteid)
            end
        elseif(self.was_active and self.status == 0 and not preview.do_prev) then
            -- if the player didn't do anything while this note was active, then he missed it
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
    end

    function e:reset()
        self.status = 0
        self.was_active = false
        self.active = false
    end

    return e
end

function staff(enemy, ents_vect, state)
    local s = {}
    s.startx = 22
    s.starty = 19
    s.x = s.startx
    s.y = s.starty
    s.preview = {}
    s.preview.do_prev = true

    local notes = enemy.notes
    s.enemy = enemy
    s.cursor = cursor(5, 10, enemy.speed, s)
    s.missed_cnt = 0
    s.total_notes=#notes
    s.notes_vect = {}
    
    -- add notes to the staff
    for n in all(notes) do
        local note = note(s.x, s.y, n, s.cursor, s.preview)
        add(ents_vect, note)
        add(s.notes_vect, note)
        s.x += _global.notes_distance_in_px
    end

    add(ents_vect, s.cursor)
    s.cursor.running = true

    function s:draw() end
    function s:update() 
        self.missed_cnt = 0
        for n in all(self.notes_vect) do
            if(n.status == -1) self.missed_cnt+=1
        end
    end

    -- this function is called by the cursor when it finishes running
    function s:done()
        if(not self.preview.do_prev)then
            printh("finished "..self.missed_cnt)
            -- return to previous state with the result
            -- add result 
            curstate=state

            local dmg_given = self.total_notes-self.missed_cnt
            local dmg_taken = self.missed_cnt

            state:duel_ended(dmg_taken, dmg_given, self.enemy)
        else
            self.preview.do_prev = false
            for n in all(s.notes_vect) do
                n:reset()
            end
            self.cursor:relaunch()
        end
    end

    return s
end

function ghero_state(enemy, prev_state)
    local s={}
    local ents={}
    -- local notes = {0,1,1,2,3}

    add(ents, staff(enemy, ents, prev_state))

    s.update=function()
        for u in all(ents) do
            u:update()
        end
    end

    s.draw=function()
        cls()
        camera(0,0)
        for d in all(ents) do
            d:draw()
        end
    end

    return s
end