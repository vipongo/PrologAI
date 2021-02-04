const QBOT_ROUTE = "ws://localhost:3000/qbot";
const AI_ROUTE = "ws://localhost:4000/ia";
var AI_SOCKET = connectAI();
var QBOT_SOCKET = connectChatBot();
const QBOT_INPUT = document.getElementById("questionInput");
const QBOT_OUTPUT = document.getElementById("qbotResponse")
const AI_INPUT = document.getElementById("userInput");
var LAST_PLAYED = "JAUNE"


/**
 * Event called when the user enter an input.
 */

AI_INPUT.onkeydown = (event) =>
     {
         if (event.key === "Enter")
         {
             let message = JSON.stringify(convertCommand(AI_INPUT.value));
             console.log("sending message \"" + message + "\"");
             if (message !== "error")
             {
                 //AI_SOCKET.send(message);

             }

             AI_INPUT.value = "";
         }
     };

/**
 * Event called when the user enter a question.
 */

QBOT_INPUT.onkeydown = (event) =>
    {
        if (event.key === "Enter")
        {
            console.log("sending message \"" + QBOT_INPUT.value + "\"");
            QBOT_SOCKET.send(JSON.stringify({message: QBOT_INPUT.value}));
            QBOT_INPUT.value = "";
        }
    };


/**
 * Make the connection to the prolog AI server.
 * @returns {WebSocket}
 */
function connectAI()
{
    const connection = new WebSocket(AI_ROUTE);
    connection.onerror = (error) => {
        console.log(error)
    };
    connection.onopen = () => {
        console.log('AI connected successfully.')
    };
    connection.onmessage = (event) => {
        console.log("Response: '" + event.data + "'");
    };


    return connection
}

/**
 * Make the connection to the prolog QBot server.
 * @returns {WebSocket}
 */
function connectChatBot()
{
    const connection = new WebSocket(QBOT_ROUTE);
    connection.onerror = (error) => {
        console.log(error)
    };
    connection.onopen = () => {
        console.log('QBOT connected successfully.');
    };
    connection.onmessage = (event) => {
        let response = cleanOutput(event.data);

        console.log("Received message: '" + response + "'");
        QBOT_OUTPUT.value = response;
    };


    return connection
}

function cleanOutput(text)
{
    text = text.replace("\"", "");
    text = text.replace("\"", "");
    let sentences = text.split(".");
    sentences.forEach((s) => {
        if (typeof s !== 'string') return '';
        return s.charAt(0).toUpperCase() + s.slice(1) + "."}
    );
    return sentences.join()
}

function convertCommand(text)
{
    let tokens = text.split("-");
    let color = tokens[0].toUpperCase();
    switch(color){
        case "JAUNE":
            color ="yellow";
            break;
        case "BLEU":
            color ="blue";
            break;
        case "ROUGE":
            color ="red";
            break;
        case "VERT":
            color ="green";
            break;
    }

    let action = tokens[1].toUpperCase();
    let coord = tokens[2].toUpperCase();
    let x = "ABCDEFGHI".indexOf(coord[0]);
    if (x === -1)
        return "error x";
    let y = parseInt(coord[1]) - 1;
    if (y < 0 || y > 8)
        return `error y = ${y}`;
    switch (action) {
        case "MUR":
            let direction = (tokens[3].toUpperCase() === "V") ? "Vertical" : "Horizontal";
            placeFence(color,tokens[3].toUpperCase() === "V", x + 1, y + 1);
            LAST_PLAYED = tokens[0].toUpperCase();
            return {color: "", direction: direction, x: x, y: y};

        
        
        case "JAUNE":
            if(LAST_PLAYED === "VERT"){
                move("yellow", x + 1, y + 1);
                LAST_PLAYED = "JAUNE";
                return {color: "yellow", direction : "", x: x, y: y};
            }
            else
            {
                console.log("Not the player turn");
                console.log(LAST_PLAYED);
                break;
            }

        case "BLEU":
            if(LAST_PLAYED === "JAUNE")
            {
            move("blue", x + 1, y + 1);
            LAST_PLAYED = "BLEU";
            return{color: "blue", direction : "", x: x, y: y};
            }
            else
            {
                console.log("Not the player turn");
                console.log(LAST_PLAYED);
                break;
            }

        case "ROUGE":
            if(LAST_PLAYED === "BLEU")
            {
            move("red", x + 1, y + 1);
            LAST_PLAYED = "ROUGE";
            return {color: "red", direction : "", x: x, y: y};
            }
            else
            {
                console.log("Not the player turn");
                console.log(LAST_PLAYED);
                break;
            }

        case "VERT":
            if(LAST_PLAYED === "ROUGE")
            {
            move("green", x + 1, y + 1);
            LAST_PLAYED = "VERT";
            return {color: "green", direction : "", x: x, y: y};
            }
            else
            {
                console.log("Not the player turn");
                console.log(LAST_PLAYED);
                break;
            }
        default:
            return "error action";
    }
}
