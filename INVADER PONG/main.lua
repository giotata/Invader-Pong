
push = require 'push'

Class = require 'class'

require 'Paddle'

require 'Ball'

require 'Bullet'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

function love.load()
    
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')

    math.randomseed(os.time())

    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['accelerate'] = love.audio.newSource('sounds/accelerate.wav', 'static'),
        ['shoot'] = love.audio.newSource('sounds/shoot.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    player1Score = 0
    player2Score = 0

    servingPlayer = 1

    player1 = Paddle(5, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 50, 5, 20)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    obstacles = {}

    bullets = {}

    gameState = 'start'
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
--[[
        if ball:collides(obstacle) then
            ball.dx = -ball.dx * 1.03
            
            if ball.x < obstacle.x then
                ball.x = obstacle.x - 4
            else
                ball.x = obstacle.x + obstacle.width + 4
            end

            sounds['paddle_hit']:play()
        end
--]]
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end
 
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
                for i=1, #bullets do
                    bullets[i] = nil
                end
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
                for i=1, #bullets do
                    bullets[i] = nil
                end
            end
        end
    end

    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    if gameState == 'play' then
        ball:update(dt)
    end

    if math.floor(ball.y + (player2.x - ball.x)*(ball.dy/ball.dx)) > player2.y + 10 then
        player2.dy = PADDLE_SPEED
    elseif math.floor(ball.y + (player2.x - ball.x)*(ball.dy/ball.dx)) < player2.y + 10 then
        player2.dy = -PADDLE_SPEED
    else
        player2.dy = 0
    end

    player1:update(dt)
    player2:update(dt)

    for k, v in pairs(bullets) do
        v:update(dt)
    end
end

function love.keypressed(key)
    if gameState == 'play' then
        if key == 'space' then
            fireRound(player1.x + player1.width,player1.y + player1.height/2 - 1,500)
            sounds['shoot']:play()
        end
    end

    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            gameState = 'serve'

            ball:reset()

            player1Score = 0
            player2Score = 0

            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

function love.draw()

    push:apply('start')

    love.graphics.clear(107/255, 235/255, 255/255, 255/255)

    love.graphics.setFont(smallFont)
    love.graphics.setColor(0,0,1,1)


    displayScore()
    love.graphics.setColor(0.5,0,1,1)

    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then

    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end
    
    love.graphics.setColor(0,0,1,1)
    player1:render()

    love.graphics.setColor(1,0,0,1)
    player2:render()

    love.graphics.setColor(0.5,0,1,1)
    ball:render()

    for k, v in pairs(bullets) do
        v:render()
    end

    love.graphics.setColor(255/255,132/255,38/255,1)
    for k, v in pairs(obstacles) do
        v:render()
    end

    push:apply('end')
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(0,0,1,1)
    love.graphics.print(tostring(player1Score), 30, 10)
    love.graphics.setColor(1,0,0,1)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH -50, 10)
end
--[[
function spawnObstacle()
    local obstacle = Paddle()
    obstacle.width = 5
    obstacle.height = 20 
    obstacle.x = math.random(0,VIRTUAL_WIDTH-obstacle.width)
    obstacle.y = math.random(0,VIRTUAL_HEIGHT-obstacle.height)

    table.insert(obstacles, obstacle)
end
--]]
function fireRound(px,py,pdx)
    local bullet = Bullet()
    bullet.x = px
    bullet.y = py
    bullet.dx = pdx

    table.insert(bullets, bullet)
end