

GAME_DATA = {
    "players" : {
        "blue": {"x" :  5, "y" : 9, "fences": 5, "goalY": 1},
        "red": {"x" :  5, "y" : 1, "fences": 5, "goalY": 9},
        "yellow": {"x" :  1, "y" : 5, "fences": 5, "goalX": 9},
        "green": {"x" :  9, "y" : 5, "fences": 5, "goalX": 1}
    },
    "fences" : [
    ],
};

function move(color, x, y)
{
    if(canMove(color, x, y))
    {
        GAME_DATA.players[color]['x'] = x;
        GAME_DATA.players[color]['y'] = y;
        drawUpdate();
    }
}

function canMove(color, toX, toY)
{
    let fromX = GAME_DATA.players[color]['x'];
    let fromY = GAME_DATA.players[color]['y'];

    if(toX === fromX && toY === fromY)
    {
        //console.log('invalid move position : already here.');
        return false
    }

    if(toX <= 0 || toX > 9 || toY <= 0 || toY > 9)
    {
        //console.log('invalid move position : out of bound.');
        return false;
    }

    // TODO: Leap frog

    //if(toX <= )

    //check if player is landing on another one
    for(let [color, player] in GAME_DATA.players)
    {
        //console.log(color);
        if(player['x'] === toX && player['y']=== toY)
        {
            //console.log("Already a player here!");
            return false;
        }
    }
    //check if fence is blocking
    for(const fence of GAME_DATA.fences)
    {
        if(fence.isVertical===false)
        {
            if(fence.x === toX)
            {
                //console.log("fence blocking");
                return false;
            }
        }
        else
        {
            if(fence.y === toY)
            {
                //console.log("fence blocking");
                return false;
            }
        }
    }

    /*if((fromX - toX + fromY - toY) !== 1)
    {
        console.log('invalid move position : too far away.');
        return false
    }*/
    return true;

}


function placeFence(color, isVertical, x, y)
{
    console.log(GAME_DATA);
    console.log(color);
    if(canPlaceFence(isVertical, x, y) && GAME_DATA.players[color]['fences'] > 0)
    {
        GAME_DATA.fences.push({"x": x, "y": y, "isVertical": isVertical});
        GAME_DATA.players[color]["fences"]-=1;
        drawUpdate();
    }
}

function canPlaceFence(isVertical, x, y)
{
    if(x <= 0 || x >= 9 || y <= 0 || y >= 9)
    {
        console.log('invalid fence position : out of bound.');
        return false;
    }

    for(const fence of GAME_DATA.fences)
    {
        if(fence.x === x && fence.y === y)
        {
            console.log('invalid fence position : already a fence here.');
            return false
        }

        if(isVertical && (y === fence.y + 1 && fence.x === x))
        {
            console.log('invalid fence position : already a fence here.');
            return false
        }

        if(!isVertical && (y === fence.y && fence.x === x + 1))
        {
            console.log('invalid fence position : already a fence here.');
            return false
        }

        if(fence.isVertical && (y === fence.y - 1 && fence.x === x))
        {
            console.log('invalid fence position : already a fence here.');
            return false
        }

        if(!fence.isVertical && (y === fence.y && fence.x === x - 1))
        {
            console.log('invalid fence position : already a fence here.');
            return false
        }
    }
    // TODO: path finding
    return true;
}

function next_move(color)
{
    let path;
    if(color === "yellow")
    {
        let y = GAME_DATA.players.yellow.y;
        let x = GAME_DATA.players.yellow.x;
        path = pathfinding_yellow([[x, y]], false, false);
    }
    else if(color === "blue")
    {
        let y = GAME_DATA.players.blue.y;
        let x = GAME_DATA.players.blue.x;
        path = pathfinding_blue([[x, y]], false, false);
    }
    else if(color === "red")
    {
        let y = GAME_DATA.players.red.y;
        let x = GAME_DATA.players.red.x;
        path = pathfinding_red([[x, y]], false, false);
    }
    else if(color === "green")
    {
        let y = GAME_DATA.players.green.y;
        let x = GAME_DATA.players.green.x;
        path = pathfinding_green([[x, y]], false, false);
    }

    if (path !== null)
    {
        return path[1];
    }

}

function pathfinding_yellow(path, from_above, from_below)
{
    let y = path[path.length - 1][1];
    let x = path[path.length - 1][0];
    if(x === 9)
    {
        return path;
    }
    else if (canMove("yellow", x + 1, y))
    {
        path.push([x + 1, y]);
        return pathfinding_yellow(path, false, false);
    }
    else
    {
        // Create a shallow copy of path.
        let above_path = path.slice();
        // Create a shallow copy of path.
        let below_path = path.slice();
        // Avoid going back
        if (!from_above)
        {

            // Go up
            if(canMove("yellow", x, y - 1))
            {
                above_path.push([x, y - 1]);
                above_path = pathfinding_yellow(above_path, true, false);
                if(from_below)
                {
                    // Only way
                    return above_path;
                }
            }
            else if(from_below)
            {
                // Blocked
                return null;
            }
        }
        // Avoid going back
        if (!from_below)
        {
            // Go down
            if(canMove("yellow", x, y + 1))
            {
                below_path.push([x, y + 1]);
                below_path = pathfinding_yellow(below_path, false, true);
                if(from_above)
                {
                    // Only way
                    return below_path;
                }
            }
            else if(from_above)
            {
                // Blocked
                return null;
            }
        }

       if(above_path.length >= below_path.length)
       {
           return above_path;
       }
       else
       {
           return below_path;
       }
    }
}

function pathfinding_green(path, from_above, from_below)
{
    let y = path[path.length - 1][1];
    let x = path[path.length - 1][0];
    if(x === 1)
    {
        return path;
    }
    else if (canMove("green", x - 1, y))
    {
        path.push([x - 1, y]);
        return pathfinding_green(path, false, false);
    }
    else
    {
        // Create a shallow copy of path.
        let above_path = path.slice();
        // Create a shallow copy of path.
        let below_path = path.slice();
        // Avoid going back
        if (!from_above)
        {
            // Go up
            if(canMove("green", x, y - 1))
            {
                above_path.push([x, y - 1]);
                above_path = pathfinding_green(above_path, true, false);
                if(from_below)
                {
                    // Only way
                    return above_path;
                }
            }
            else if(from_below)
            {
                // Blocked
                return null;
            }
        }
        // Avoid going back
        if (!from_below)
        {
            // Go down
            if(canMove("green", x, y + 1))
            {
                below_path.push([x, y + 1]);
                below_path = pathfinding_green(below_path, false, true);
                if(from_above)
                {
                    // Only way
                    return below_path;
                }
            }
            else if(from_above)
            {
                // Blocked
                return null;
            }
        }

       if(above_path.length >= below_path.length)
       {
           return above_path;
       }
       else
       {
           return below_path;
       }
    }
}

function pathfinding_blue(path, from_left, from_right)
{
    let x = path[path.length - 1][0];
    let y = path[path.length - 1][1];
    if(y === 1)
    {
        return path;
    }
    else if (canMove("blue", x, y - 1))
    {
        path.push([x, y - 1]);
        return pathfinding_blue(path, false, false);
    }
    else
    {
        // Create a shallow copy of path.
        let left_path = path.slice();
        // Create a shallow copy of path.
        let right_path = path.slice();
        // Avoid going back
        if (!from_left)
        {
            // Go left
            if(canMove("blue", x - 1, y))
            {
                left_path.push([x -1 , y]);
                left_path = pathfinding_blue(left_path, true, false);
                if(from_right)
                {
                    // Only way
                    return left_path;
                }
            }
            else if(from_right)
            {
                // Blocked
                return null;
            }
        }
        // Avoid going back
        if (!from_right)
        {
            // Go rigt
            if(canMove("blue", x + 1, y ))
            {
                right_path.push([x + 1, y]);
                right_path = pathfinding_blue(right_path, false, true);
                if(from_left)
                {
                    // Only way
                    return right_path;
                }
            }
            else if(from_left)
            {
                // Blocked
                return null;
            }
        }

       if(left_path.length >= right_path.length)
       {
           return left_path;
       }
       else
       {
           return right_path;
       }
    }
}

function pathfinding_red(path, from_left, from_right)
{
    let y = path[path.length - 1][1];
    let x = path[path.length - 1][0];
    if(y === 9)
    {
        return path;
    }
    else if (canMove("red", x, y + 1))
    {
        path.push([x, y + 1]);
        return pathfinding_red(path, false, false);
    }
    else
    {
        // Create a shallow copy of path.
        let left_path = path.slice();
        // Create a shallow copy of path.
        let right_path = path.slice();
        // Avoid going back
        if (!from_left)
        {
            // Go left
            if(canMove("red", x - 1, y))
            {
                left_path.push([x - 1 , y]);
                left_path = pathfinding_red(left_path, true, false);
                if(from_right)
                {
                    // Only way
                    return left_path;
                }
            }
            else if(from_right)
            {
                // Blocked
                return null;
            }
        }
        // Avoid going back
        if (!from_right)
        {
            // Go rigt
            if(canMove("red", x + 1, y ))
            {
                right_path.push([x + 1, y]);
                right_path = pathfinding_red(right_path, false, true);
                if(from_left)
                {
                    // Only way
                    return right_path;
                }
            }
            else if(from_left)
            {
                // Blocked
                return null;
            }
        }

       if(left_path.length >= right_path.length)
       {
           return left_path;
       }
       else
       {
           return right_path;
       }
    }
}


