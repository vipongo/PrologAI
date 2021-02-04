function draw()
{
    CANVAS = document.getElementById('board');
    CANVAS.height = CANVAS_HEIGHT;
    CANVAS.width = CANVAS_WIDTH;
    CTX = CANVAS.getContext("2d");
    if (CTX)
    {
        drawUpdate()
    }
}

function drawUpdate()
{
        drawBoard();
        ["red", "blue", "green", "yellow"].forEach(function (color) {drawPlayer(color);});
        GAME_DATA.fences.forEach(function (fence) {drawFence(fence);});
}

function drawBoard() 
{
    CTX.strokeStyle = "black";
    CTX.font = '34px serif';
    for(let i=1; i<10; i++) 
    {
        CTX.fillStyle = "black";
        CTX.fillText("ABCDEFGHI"[i-1], TEXT_START_X + i * SQUARE_SIZE, TEXT_START_Y + SQUARE_SIZE * 0.25);
        for(let j=1; j<10; j++) 
        {
            CTX.fillStyle = "black";
            CTX.fillText(10 - i, TEXT_START_X, TEXT_START_Y + SQUARE_SIZE * 0.5 + i * SQUARE_SIZE);
            CTX.fillStyle = "gray";
            let posX = GRID_START_X + j * SQUARE_SIZE;
            let posY = GRID_START_Y + (10 - i) * SQUARE_SIZE;
            CTX.fillRect(posX, posY, SQUARE_SIZE, SQUARE_SIZE);
            CTX.strokeRect(posX, posY, SQUARE_SIZE, SQUARE_SIZE);       
        }
    }
  }

function drawPlayer(color)
{
    let player = GAME_DATA.players[color];
    CTX.fillStyle = color;
    CTX.strokeStyle = "black";
    let pawn = new Path2D();
    pawn.arc(PAWN_START_X + player.x * SQUARE_SIZE, PAWN_START_Y + (10 - player.y) * SQUARE_SIZE, PAWN_SIZE, 0, 2 * Math.PI);
    CTX.fill(pawn);
    CTX.stroke(pawn);
}

function drawFence(fence)
{
    CTX.fillStyle = "firebrick";
    CTX.strokeStyle = "black";
    let length = (fence.isVertical) ? THIN_WALL : LONG_WALL;
    let height = (fence.isVertical) ? LONG_WALL : THIN_WALL;
    let posX = GRID_START_X + (fence.x+1) * SQUARE_SIZE;
    let posY = GRID_START_Y + (9 - fence.y) * SQUARE_SIZE;
    if (fence.isVertical)
    {
        posX -= length * 0.5;
    }
    else
    {
        posX -= SQUARE_SIZE;
        posY -= height * 0.5 - SQUARE_SIZE;
    }
    CTX.fillRect(posX, posY, length, height);
    CTX.strokeRect(posX, posY, length, height);
}

