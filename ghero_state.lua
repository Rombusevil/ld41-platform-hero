function cursor(x,y)
    local anim_obj=anim()
    anim_obj:add(16,1,0.01,1,5)

    local e=entity(anim_obj)
    e:setpos(x,y)
    e:set_anim(1)

    local bounds_obj=bbox(8,8*5, 2, 0, 3, 1)
    e:set_bounds(bounds_obj)
    --e.debugbounds=true

    function e:update() end
    return e
end

-- 0 left, 1 right, 2 up, 3 down, 
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

        if(not self.active and self.was_active and lastone)then
            -- notify done
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
    
    -- add notes to the staff
    for i = 1, #notes, 1 do
    --for n in all(notes) do
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
            -- move notes
            n:setx(n.x - self.speed)
        end

        -- play metronome sound
        if(self.metronome_ctr % (self.notes_distance_in_px/self.speed) == 0 
            or self.metronome_ctr == 0 ) then 
            sfx(5) --metronome 22 es la distancia en px de las notas
        end
        self.metronome_ctr+=1

    end

    -- this function is called by the cursor when it finishes running
    function s:done()
        if(not self.preview.do_prev)then

            -- get misses
            self.missed_cnt = 0
            for n in all(self.notes_vect) do
                -- update missed notes count
                if(n.status == -1) self.missed_cnt+=1 
            end

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
        --rectfill(0,14, 128, 67, 13)
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