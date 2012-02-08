-- chest lockable with an item

-- Handy definitions

local open_spec="invsize[8,9;]"
			.."list[current_name;key;0,0;1,1;]"
			.."list[current_name;lock;0,2;1,1;]"
			.."list[current_name;main;2,0;5,4;]"
			.."list[current_player;main;0,5;8,4;]"

local locked_spec="invsize[8,9;]"
			.."list[current_name;key;0,0;1,1;]"
			.."list[current_player;main;0,5;8,4;]"

local empty_twenty={
            "", "", "", "", "",
            "", "", "", "", "",
            "", "", "", "", "",
            "", "", "", "", "",
        }

-- Craft recipes

minetest.register_craft({
    output = 'klchest:key',
    recipe = {
        {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
        {'','','default:steel_ingot'},
    }
})

minetest.register_craft({
    output = 'klchest:lock',
    recipe = {
        {'','default:steel_ingot',''},
        {'default:steel_ingot','','default:steel_ingot'},
        {'','default:steel_ingot',''},
    }
})

minetest.register_craft({
	output = 'klchest:item_lockable_chest',
	recipe = {
		{'default:chest', 'klchest:lock'},
	}
})

minetest.register_craft({
	output = 'klchest:item_lockable_chest',
	recipe = {
		{'default:wood', 'default:wood', 'default:wood'},
		{'default:wood', 'klchest:lock', 'default:wood'},
		{'default:wood', 'default:wood', 'default:wood'},
	}
})

minetest.register_craft({
    output = 'klchest:key_duplicator',
    recipe = {
        {'default:wood', '', 'default:wood'},
    }
})

-- Objects

minetest.register_craftitem('klchest:lock', {
    description = 'Lock',
    inventory_image = 'chest_lock.png',
})

minetest.register_node("klchest:key_duplicator", {
    tile_images = {"default_wood.png", "default_wood.png", "default_wood.png",
        "default_wood.png", "default_wood.png", "chest_chest_front.png"},
    description = 'Key duplicator',
    paramtype2 = "facedir",
    metadata_name = "generic",
    material = minetest.digprop_woodlike(3.0),
})

minetest.register_tool('klchest:key', {
    description = 'Key',
    stack_max = 1,
    inventory_image = 'chest_key.png',
    tool_digging_properties = {
        basetime = 0,
        dt_weight = 0,
        dt_crackiness = 0,
        dt_crumbliness = 0,
        dt_cuttability = 0,
        basedurability = 0,
        dd_weight = 0,
        dd_crackiness = 0,
        dd_crumbliness = 0,
        dd_cuttability = 0,
    },
    on_use = function(itemstack, user, pointed_thing)
        local meta=minetest.env:get_meta(pointed_thing.under)
        local node=minetest.env:get_node(pointed_thing.under)
        if node.name=='klchest:key_duplicator' then
            meta:set_infotext('Key:'..itemstack:get_wear())
            local inven = meta:get_inventory()
            if inven == nil then
                return
            end
            local newkey_s = inven:get_stack("newkey",1)
            if newkey_s:get_name()=='klchest:key' and newkey_s:get_wear()==0 then
                newkey_s:add_wear(itemstack:get_wear())
                inven:set_stack("newkey",1,newkey_s)
                meta:set_infotext('Key duplicated')
            end

        elseif node.name=='klchest:item_lockable_chest' then
            local inven = meta:get_inventory()
            if inven==nil then
                return
            end
            local lock_s = inven:get_stack("lock",1)
            if itemstack:to_string()==lock_s:to_string() then
              local status = meta:get_string("status")
              if status=="locked" and lock==key then
                  meta:set_inventory_draw_spec(open_spec)
                  meta:set_string("status", "unlocked")
              elseif status=="unlocked" and lock ~= "" then
                  meta:set_inventory_draw_spec(locked_spec)
                  meta:set_string("status", "locked")
              end
              status = meta:get_string("status")
		      meta:set_infotext("Chest is "..status)
            end
        end
    end,
})

minetest.register_node("klchest:item_lockable_chest", {
	description = "Lockable chest",
	tile_images = {"default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png",
		"default_chest_side.png", "chest_chest_front.png"},
	inventory_image = minetest.inventorycube("default_chest_top.png", 
        "chest_chest_front.png", "default_chest_side.png"),
	paramtype2 = "facedir",
	metadata_name = "generic",
	material = minetest.digprop_woodlike(3.0),
})

-- Callbacks

minetest.register_on_placenode(function(pos, newnode, placer)
    if newnode.name == "klchest:key_duplicator" then
        local meta = minetest.env:get_meta(pos)
        meta:get_inventory():set_list("newkey", {""})
        meta:set_inventory_draw_spec(
            "invsize[8,9;]list[current_name;newkey;4,2;1,1;]"
            .."list[current_player;main;0,5;8,4;]"
        )
        meta:set_infotext("---")

    elseif newnode.name == "klchest:item_lockable_chest" then
		local meta = minetest.env:get_meta(pos)
        local inven = meta:get_inventory()
		inven:set_list("key", {""})
		inven:set_list("lock", {""})
		inven:set_list("main", empty_twenty)
		meta:set_inventory_draw_spec(open_spec)
        meta:set_string("status", "unlocked")
		meta:set_infotext("Chest is unlocked")

    end
end)

minetest.register_on_punchnode(
  function(pos, node)
      if node.name=='klchest:key_duplicator' then
          local meta = minetest.env:get_meta(pos)
          meta:set_infotext('---')

      elseif node.name=="klchest:item_lockable_chest" then
          local meta = minetest.env:get_meta(pos)
          local inven = meta:get_inventory()
          local status = meta:get_string("status")
          local lock = inven:get_list("lock")[1]
          local key = inven:get_list("key")[1]
          local lock_s = inven:get_stack("lock",1)
          local key_s = inven:get_stack("key",1)

          if lock=="klchest:key" and key=="klchest:key" then
              local w = math.random(65536)
              key_s:add_wear(w)
              inven:set_stack("key",1,key_s)
              lock_s:add_wear(w)
              inven:set_stack("lock",1,lock_s)
          end
          
          local empty = true
          if lock~="" then
              empty = false
          elseif key ~="" then
              empty = false
          else
              for i,v in pairs(inven:get_list("main")) do
                  if v~="" then
                      empty = false
                      break
                  end
              end
          end
          if empty then
              meta:set_allow_removal(true)
          else
              meta:set_allow_removal(false)
          end
          if status=="locked" and lock==key then
              meta:set_inventory_draw_spec(open_spec)
              meta:set_string("status", "unlocked")
          elseif status=="unlocked" and lock ~= "" then
              meta:set_inventory_draw_spec(locked_spec)
              meta:set_string("status", "locked")
          end
          status = meta:get_string("status")
		  meta:set_infotext("Chest is "..status)
      end
  end
)
