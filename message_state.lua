-- state
function message_state(msg_text, goto_state, duration_seconds)
    local s={}

    sfx(8)
    
    local time=0
    local msg=tutils(
        {text="",
        centerx=true,
        centery=true,
        fg=9,
        bg=0,
        bordered=true,
        shadowed=true,
        sh=1})

    s.update=function()
        if(time > duration_seconds)then
            curstate=goto_state
        end

        time+=1/60
    end

    s.draw=function()
        cls()
        camera(0,0)
        fillp(0b0001001001001000)
        rectfill(0,0,128,128,1)
        msg.text = msg_text
        msg:draw()
        fillp()
    end

    return s
end