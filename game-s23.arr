use context essentials2021
include shared-gdrive("dcic-2021", "1wyQZj_L0qqV9Ekgr9au6RX2iqt2Ga8Ep")
include shared-gdrive("project-2-support-fall-2022", "1vDKhda2-jwmnT_MFG2LV7KPkum1govhk") 
include reactors
import lists as L
   
# the URL of the Google Configuration Sheet to use for your maze
ssid = "1W8OpaJLtw0oO0LUVUHmcqHp7iT7YyUF2maVcckdW5nM"
# load maze from spreadsheet into List<List<String>>
maze-grid  = load-maze(ssid) 
# load item positions from spreadsheet into Table
item-table = load-items(ssid) 

# load all item/background-component images
floor-img  = load-texture("tile.png")
wall-img   = load-texture("wall.png")
superhero-img  = load-texture("alien.png")
computer-img = load-texture("computer.png")
popcorn-img = load-texture("popcorn.png")
tickets-img =load-texture("tickets.png")
wetfloorsign-img =load-texture("wetfloorsign.png")
wormhole-img = load-texture("wormhole.png")


# Define your GameState datatype here
data GameState:
  |game(superhero :: Superhero, gadgets :: List<Gadgets>)
end

data Superhero:
  |superhero(img :: Image, x :: Number, y :: Number, stamina :: Number)
end

data Gadgets:
  |computer(img :: Image, x :: Number, y :: Number)
  |popcorn(img :: Image, x :: Number, y :: Number)
  |tickets(img :: Image, x :: Number, y :: Number)
  |wet(img :: Image, x :: Number, y :: Number)
end


# Making background
fun background-generator(new-data :: List<List<String>>) -> Image:
  doc: ```Generates the entire image of the maze by inputting a list of list of strings. Each list 
  of strings corresponds to an image of a row```
  cases(List) new-data:
    |empty => empty-image
    |link(fst, rst)=> 
      above(background-generator-2(fst), background-generator(rst))
      end
end
  
fun background-generator-2(row-data :: List<String>) -> Image:
  doc: "Generates the image of a single row of the maze after inputting a list of strings. With 'x' corresponding to wall and 'o' corresponding to floor"
  cases(List) row-data:
    |empty => empty-image
    |link(fst, rst)=> 
      if fst == "x":
          beside(wall-img, background-generator-2(rst))
      else:
          beside(floor-img, background-generator-2(rst))
      end
  end
end

BACKGROUND = background-generator(maze-grid)


# Putting gadgets onto background
fun put-gadgets(r :: Row)-> Gadgets:
  doc: "Generates a given variant of the datatype of gadget depending on name of the first column"
  if r["name"] == "Tickets":
    tickets(tickets-img, r["x"], r["y"])
  else if r["name"] == "WetFloorSign":
    wet(wetfloorsign-img, r["x"], r["y"])
  else if r["name"] == "Popcorn":
    popcorn(popcorn-img, r["x"], r["y"])
  else:
    computer(computer-img, r["x"], r["y"])
  end
where:
  put-gadgets(item-table.row-n(0)) is tickets(tickets-img, 7, 1)
  put-gadgets(item-table.row-n(11)) is wet(wetfloorsign-img, 3, 1)
end
    
fun real-coord(raw-coord :: Number)-> Number:
  doc: "Converts the pixel coordinates to image coordinates on the maze"
  (raw-coord * 30) + 15
where:
  real-coord(15) is 465 #raw-coord is a positive integer
  real-coord(0) is 15 #raw-coord is zero
end

gadget-table = build-column((transform-column(transform-column(item-table, "x", real-coord), 
      "y", real-coord)), "Gadgets", put-gadgets)

gadget-list = gadget-table.get-column("Gadgets")


# Define the starting configuration of your GameState
init-state = game(superhero(superhero-img, 45, 45, 60), gadget-list)

fun gadget-placer(first-gadg :: List<Gadgets>, back :: Image)-> Image:
  doc: "Places the gadgets contained in the item-table on the maze through place-image"
  cases (List) first-gadg:
    |empty => back
    |link(fst, rst) => place-image(fst.img, fst.x, fst.y, gadget-placer(rst, back))
  end
end

fun draw-game(state :: GameState) -> Image:
  doc: "Places the superhero on the maze as well as the gadgets from item-table"
  superhero-state = place-image(superhero-img, state.superhero.x, state.superhero.y, BACKGROUND)
  gad-plac = gadget-placer(state.gadgets, superhero-state)
  beside(gad-plac, draw-game-helper(state))
end


# Creating stamina bar

fun stamina-bar(new-x :: Number, new-y :: Number, state :: GameState) -> Number:
  doc: ```changes the magnitude of the stamina bar based on the new coordinates of the superhero 
  and its interactions with the gadgets```
  if helper(new-x, new-y, state.gadgets):
    a = helper-2(new-x, new-y, state.gadgets)
    cases(Gadgets) a:
      | popcorn(_,_,_) => state.superhero.stamina + 10 
      | tickets(_,_,_) => 60
      | wet(_,_,_) => 10
      | computer(_,_,_) => 0
    end    
  else:
    state.superhero.stamina - 2
  end
where:
  stamina-bar(5, 6, game(superhero(superhero-img, 5, 6, 10), [list: computer(computer-img, 40, 30), tickets(tickets-img, 30, 40)])) is 8
  stamina-bar(5, 20, game(superhero(superhero-img, 80, 6, 10), [list: computer(computer-img, 30, 30)
        , tickets(tickets-img, 30, 40)])) is 8
end

fun key-pressed(state :: GameState, key :: String) -> GameState:
  doc: ```corresponds the four valid keys to a movement of the superhero, producing a new location 
       of the superhero and stamina bar size```
    new-superhero = 
    if (key == "w") and (respect-walls(state, "w")):
      superhero(superhero-img, state.superhero.x, state.superhero.y - 30, 
        stamina-bar(state.superhero.x + 0, state.superhero.y - 30, state))
          
    else if (key == "a") and (respect-walls(state, "a")):
      superhero(superhero-img, state.superhero.x - 30, state.superhero.y, 
        stamina-bar(state.superhero.x - 30, state.superhero.y + 0, state))
    
    else if (key == "s") and (respect-walls(state, "s")):
      superhero(superhero-img, state.superhero.x, state.superhero.y + 30, 
        stamina-bar(state.superhero.x + 0, state.superhero.y + 30, state))
    
    else if (key == "d") and (respect-walls(state, "d")):
      superhero(superhero-img, state.superhero.x + 30, state.superhero.y, 
        stamina-bar(state.superhero.x + 30, state.superhero.y + 0, state))
    
    else:
      superhero(superhero-img, state.superhero.x, state.superhero.y, 
        stamina-bar(state.superhero.x, state.superhero.y, state))
  end
  game(new-superhero, L.filter(lam(r): 
      not(player-on-gadget(new-superhero.x, new-superhero.y, r)) end, state.gadgets))
  
where:
  key-pressed(game(superhero(superhero-img, 225, 45, 16), [list: tickets(tickets-img, 525, 285), wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]), "w") is 
  game(superhero(superhero-img, 225, 45, 14),[list: tickets(tickets-img, 525, 285), 
      wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]) 
  # superhero moves to empty floor cell without gadgets 
  
  key-pressed(game(superhero(superhero-img, 45, 45, 20), [list: wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]), "w") is 
  game(superhero(superhero-img, 45, 45, 18), 
    [list: wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]) 
  # superhero moves to blocked wall cell
  
  key-pressed(game(superhero(superhero-img, 225, 45, 16), [list: tickets(tickets-img, 255, 45), wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]), "d") is 
  game(superhero(superhero-img, 255, 45, 60), [list: wet(wetfloorsign-img, 105, 45), 
      popcorn(popcorn-img, 135, 75)]) # superhero moves to floor cell with ticket
  
  key-pressed(game(superhero(superhero-img, 135, 45, 22), [list: tickets(tickets-img, 255, 45), wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]), "s") is 
  game(superhero(superhero-img, 135, 75, 32), [list: tickets(tickets-img, 255, 45), 
      wet(wetfloorsign-img, 105, 45)]) # superhero moves to floor cell with popcorn
  
  key-pressed(game(superhero(superhero-img, 75, 45, 30), [list: tickets(tickets-img, 255, 45), wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]), "d") is 
  game(superhero(superhero-img, 105, 45, 10), [list: tickets(tickets-img, 255, 45), 
      popcorn(popcorn-img, 135, 75)]) # superhero moves to floor cell with wetfloorsign
  
  key-pressed(game(superhero(superhero-img, 1005, 435, 40), [list: tickets(tickets-img, 255, 45), computer(computer-img, 1035, 435)]), "d") is game(superhero(superhero-img, 1035, 435, 0), [list: tickets(tickets-img, 255, 45)]) # superhero moves to floor cell with computer
end 


fun player-on-gadget(new-x :: Number, new-y :: Number, object :: Gadgets) -> Boolean:
  doc: "determines if the superhero is on the same location as the gadgets"
  (new-x == object.x) and (new-y == object.y)
where:
  player-on-gadget(5, 5, computer(computer-img, 5, 5)) is true
  player-on-gadget(6, 5, computer(computer-img, 5, 5)) is false
end

fun helper(new-x :: Number, new-y :: Number, lst :: List<Gadgets>) -> Boolean:
  doc: "tells stamina bar that player is at location of every possible gadget"
  cases(List) lst:
      |empty => false
      |link(first,rest) => 
      player-on-gadget(new-x, new-y, first) or helper(new-x, new-y, rest)
    end
where:
  helper(10, 8, [list: computer(computer-img, 5, 12)]) is false
  helper(11, 8, [list: computer(computer-img, 11, 8)]) is true
end

fun helper-2(new-x :: Number, new-y :: Number, object :: List<Gadgets>) -> Gadgets:
  doc: "if helper is true, call this helper to retrieve gadget"
    cases(List) object:
    |empty => raise("Error")
    |link(first,rest) =>
      if player-on-gadget(new-x, new-y, first):
        first
      else:
        helper-2(new-x, new-y, rest)
      end
    end
where:
 helper-2(30, 30, [list: computer(computer-img, 30, 30)]) is computer(computer-img, 30, 30)
 helper-2(30, 30, [list: tickets(tickets-img, 30, 30), computer(computer-img, 30, 30)]) is 
  tickets(tickets-img, 30, 30)
end
    
fun draw-game-helper(state :: GameState) -> Image:
  doc: "creates the image of stamina bar magnitude, which corresponds to the health of the superhero relative to full health"
  new-state = state.superhero.stamina / 60
  height-rect = new-state * image-height(BACKGROUND)
  below(rectangle(20, height-rect, "solid", "yellow"), rectangle(20, 
      image-height(BACKGROUND) - height-rect, "solid", "grey"))
end

fun respect-walls(state :: GameState, key :: String) -> Boolean:
  doc: "inhibits the superhero from going onto the wall"
  if (key == "w") and ((maze-grid.get(((state.superhero.y - 15) / 30) - 1).get(((state.superhero.x - 15)) / 30) == "x")):
    false
    
  else if (key == "a") and (maze-grid.get((state.superhero.y - 15) / 30).get(((state.superhero.x - 15) / 30) - 1) == "x"):
    false
    
  else if (key == "s") and ((maze-grid.get(((state.superhero.y - 15) / 30) + 1).get(((state.superhero.x - 15)) / 30) == "x")):
    false
    
  else if (key == "d") and (maze-grid.get((state.superhero.y - 15) / 30).get(((state.superhero.x - 15) / 30) + 1) == "x"):
    false
    
  else:
    true
  end
where:
  respect-walls(game(superhero(superhero-img, 225, 45, 16), [list: tickets(tickets-img, 255, 45), wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]), "d") is true
  respect-walls(game(superhero(superhero-img, 45, 45, 20), [list: wet(wetfloorsign-img, 105, 45), popcorn(popcorn-img, 135, 75)]), "w") is false  
end

 
fun game-complete(state :: GameState) -> Boolean:
  doc: "ends the game if the stamina value is equal to zero or superhero reaches the computer"
  state.superhero.stamina <= 0  
where:
game-complete(game(superhero(superhero-img, 50, 50, 50), [list: computer(computer-img, 50, 50)]))
    is false
  game-complete(game(superhero(superhero-img, 60, 60, 0), [list: tickets(tickets-img, 50, 50)]))
    is true
  game-complete(game(superhero(superhero-img, 60, 60, 60), [list: computer(computer-img, 50, 50)]))
    is false
end
  
maze-game =
  reactor:
    init              : init-state,
    to-draw           : draw-game,
    on-key            : key-pressed,
    title             : "Superhero Escape",
    stop-when        : game-complete
end

interact(maze-game)