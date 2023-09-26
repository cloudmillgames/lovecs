-- ** Messaging Single System **
--
-- Handles message receiving and dispatch between entities.
-- Does not clear receiver messages queue and leaves that to receiver itself.
-- Clears dispatcher messages queue once processed.
-- Does not handle situation where multiple dispatchers send the same message id.

Msging = {}

Msging.DEBUG = true
Msging.CHANNEL = "global"

-- Receiver components by default listens to global channel
Msging.Receiver = {
    channels = {Msging.CHANNEL},  -- channels this receiver wants to listen on
    msgs = {}   -- msgs incoming filled by Msging system {msg="name", data=data}, must be cleared manually
}
DefineComponent("msg_receiver", Msging.Receiver)

Msging.Dispatcher = {
    dispatch = {},      -- expects {channel="name", msg="name", data=data} per msg, messages dispatched next frame update. Cleared by Msging system once processed
    kill_after_reading = false  -- kill self entity once a msg is dispatched from this dispatcher
}
DefineComponent("msg_dispatcher", Msging.Dispatcher)

-- Helper function to queue channel-msg-data in dispatcher component
Msging.dispatch = function(dispatcher, _channel, _msg, _data)
    assert(type(dispatcher) == "table")
    assert(type(_channel) == "string")
    assert(type(_msg) == "string")
    table.insert(dispatcher.dispatch, {channel=_channel, msg=_msg, data=_data})
end

-- Checks if receiver has the message given, simplification, data is ignored
Msging.received_msg = function(receiver, _msg)
    assert(type(receiver) == "table")
    assert(type(_msg) == "string")
    for i=1,#receiver.msgs do
        if receiver.msgs[i].msg == _msg then
            return true
        end
    end
    return false
end

Msging.run = function()
    local dispatchers = CollectEntitiesWith({"msg_dispatcher"})
    local receivers = CollectEntitiesWith({"msg_receiver"})

    local channel_to_receivers = {} -- collects receiver entities by channel name
    for i=1,#receivers do
        local rec_ent = receivers[i]
        local comp = GetEntComp(rec_ent, "msg_receiver")
        assert(type(comp.channels) == "table")
        assert(type(comp.msgs) == "table")
        for j=1,#comp.channels do
            if channel_to_receivers[comp.channels[j]] == nil then
                channel_to_receivers[comp.channels[j]] = {rec_ent}
            else
                table.insert(channel_to_receivers[comp.channels[j]], rec_ent)
            end
        end
    end

    for i=1,#dispatchers do
        local dsp_ent = dispatchers[i]
        local comp = GetEntComp(dsp_ent, "msg_dispatcher")
        assert(type(comp.dispatch) == "table")
        for j=1,#comp.dispatch do
            local dmsg = comp.dispatch[j]
            assert(type(dmsg.channel) == "string")
            assert(type(dmsg.msg) == "string")
            if channel_to_receivers[dmsg.channel] ~= nil then
                for k=1,#channel_to_receivers[dmsg.channel] do
                    local rec_ent = channel_to_receivers[dmsg.channel][k]
                    local rec = GetEntComp(rec_ent, "msg_receiver")
                    table.insert(rec.msgs, {msg=dmsg.msg, data=dmsg.data})
                end
                if comp.kill_after_reading == true then
                    KillEntity(dsp_ent)
                end
            else
                print("Msging: msg-dispatch to channel no one listening on: "..dmsg.channel)
            end
        end
        -- Clear all outgoing messages after processing
        comp.dispatch = {}
    end
end
