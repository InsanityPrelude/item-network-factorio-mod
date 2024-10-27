local GlobalState = require "src.GlobalState"
local Priority = require "src.Priority"

local M = {}

M.entity_name = "spidertron"

function M.on_update(info)
  local entity = info.entity

  local trash_inv = entity.get_inventory(defines.inventory.spider_trash)
  GlobalState.deposit_inv_contents(trash_inv)

  local main_inv = entity.get_inventory(defines.inventory.spider_trunk)
  local requester_point = entity.get_requester_point()
  local requester_point = requester_point.get_section(1)

  -- fulfill reqeusts
  if main_inv ~= nil and requester_point.filters_count > 0 then
    local contents = main_inv.get_contents()
    for slot = 1, requester_point.filters_count do
      local req = requester_point.get_slot(slot)
      if req ~= nil then
        local current_count = contents[req.value] or 0
        local n_wanted = math.max(0, req.min - current_count)

        local n_withdrawn = GlobalState.withdraw_item2(
          req.value,
          n_wanted,
          Priority.DEFAULT
        )
        if n_withdrawn > 0 then
          local n_inserted = main_inv.insert({
            name = req.value,
            count = n_withdrawn,
          })
          local excess = n_withdrawn - n_inserted
          assert(excess >= 0)
          if excess > 0 then
            GlobalState.deposit_item2(
              req.value,
              excess,
              Priority.ALWAYS_INSERT
            )
          end
        end

        local shortage = n_wanted - n_withdrawn
        if shortage > 0 then
          GlobalState.register_item_shortage(
            req.value,
            entity,
            shortage
          )
        end
      end
    end
  end

  return GlobalState.get_default_update_period()
end

function M.on_remove_entity(event)
  GlobalState.put_chest_contents_in_network(event.entity)
end

function M.on_marked_for_deconstruction(event)
  GlobalState.put_chest_contents_in_network(event.entity)
end

return M
