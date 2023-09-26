-- ** Messaging Single System **
--
-- Handles message receiving and dispatch between entities.
-- Does not clear receiver messages queue and leaves that to receiver itself.
-- Clears dispatcher messages queue once processed.
-- Does not handle situation where multiple dispatchers send the same message id.

Msging = {}

Msging.DEBUG = true

Msging.Receiver = {
    channels = {},      -- List of channels this receiver wants to listen on
    msgs = {}           -- list of messages incoming filled by Msging system {msg="name", data=data}, this must be cleared by receiver itself
}
DefineComponent("msg-receiver", Msging.Receiver)

Msging.Dispatcher = {
    dispatch = {},      -- expects {channel="name", msg="name", data=data} per msg, messages dispatched next frame update. Cleared by Msging system once processed
}
DefineComponent("msg-dispatcher", Msging.Dispatcher)

Msging.run = function()
    local dispatchers = CollectEntitiesWith({"msg-dispatcher"})
    local receivers = CollectEntitiesWith({"msg-receiver"})

    local channel_to_receivers = {} -- collects receiver entities by channel name
    for i=1,#receivers do
        local rec_ent = receivers[i]
        local comp = GetEntComp(rec_ent, "msg-receiver")
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
        local comp = GetEntComp(dsp_ent, "msg-dispatcher")
        assert(type(comp.dispatch) == "table")
        for j=1,#comp.dispatch do
            local dmsg = comp.dispatch[j]
            assert(type(dmsg.channel) == "string")
            assert(type(dmsg.msg) == "string")
            if channel_to_receivers[dmsg.channel] ~= nil then
                for k=1,#channel_to_receivers[dmsg.channel] do
                    local rec_ent = channel_to_receivers[dmsg.channel][k]
                    local rec = GetEntComp(rec_ent, "msg-receiver")
                    table.insert(rec.msgs, {msg=dmsg.msg, data=dmsg.data})
                end
            else
                print("Msging: msg-dispatch to channel no one listening on: "..dmsg.channel)
            end
        end
        -- Clear all outgoing messages after processing
        comp.dispatch = {}
    end
end
