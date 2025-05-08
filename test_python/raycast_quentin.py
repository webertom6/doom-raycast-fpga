import pygame


def to_q16_16(value: float) -> int:
    """Convert float to q16.16 fixed-point"""
    raw = int(round(value * 65536))
    return wrap_32bit(raw)

def from_q16_16(value: int) -> float:
    """Convert q16.16 fixed-point to float"""
    value = wrap_32bit(value)
    return value / 65536.0

def wrap_32bit(value: int) -> int:
    """Simulate 32-bit signed integer overflow"""
    value &= 0xFFFFFFFF  # Keep 32 bits
    if value & 0x80000000:
        value -= 0x100000000
    return value

def q16_16_add(a: int, b: int) -> int:
    return wrap_32bit(a + b)

def q16_16_sub(a: int, b: int) -> int:
    """Subtract two q16.16 fixed-point numbers"""
    return wrap_32bit(a - b)

def q16_16_mul(a: int, b: int) -> int:
    product = (a * b) >> 16
    return wrap_32bit(product)

def q16_16_inverse(x: int) -> int:
    result = (1 << 32) // x
    return wrap_32bit(result)

def q16_16_div(a: int, b: int) -> int:
    if b == 0:
        return 0x7FFFFFFF
    numerator = (a << 16)
    result = numerator // b
    return wrap_32bit(result)

def abs_q16_16(x: int) -> int:
    """Return the absolute value of a q16.16 fixed-point number"""
    x = wrap_32bit(x)
    if x < 0:
        x = wrap_32bit(-x)
    return x


WIDTH, HEIGHT = to_q16_16(780), to_q16_16(490)
posX, posY = to_q16_16(3.5), to_q16_16(5.5)
dirX, dirY = to_q16_16(1), to_q16_16(0)
planeX, planeY = to_q16_16(0), to_q16_16(0.66)
zoom = False
offset = 0

def game(screen, gridMap):
    rayDirX = [0] * 780
    rayDirY = [0] * 780
    for i in range(780):
        cst = to_q16_16(0.002564102564103)
        two_i_fp = q16_16_mul(cst, to_q16_16(i))
        two_i_fp = q16_16_sub(two_i_fp, 65536)
        camX = two_i_fp
        rayDirX[i]= q16_16_add(dirX, q16_16_mul(planeX, camX))
        rayDirY[i]= q16_16_add(dirY, q16_16_mul(planeY, camX))

    hitInternal = False
    sideHit = False
    for i in range(780):
        sideDistX = to_q16_16(0)
        sideDistY = to_q16_16(0)
        deltaDistX = to_q16_16(0)
        deltaDistY = to_q16_16(0)
        perpWallDist= to_q16_16(0)
        stepX = 0
        stepY = 0
        hitInternal = False
        sideHit = False
        mapX = int(from_q16_16(posX))
        mapY = int(from_q16_16(posY))
        
        if rayDirX[i] == to_q16_16(0):
            deltaDistX = int("01111111111111111111111111111111", 2)
            stepX=1
            tmp = q16_16_sub(to_q16_16(mapX+1), posX)
            sideDistX = q16_16_mul(tmp, deltaDistX)
        elif rayDirX[i] < to_q16_16(0):
            deltaDistX = abs_q16_16(q16_16_inverse(rayDirX[i]));
            stepX = -1
            tmp = q16_16_sub(posX,to_q16_16(mapX))
            sideDistX = q16_16_mul(tmp, deltaDistX)
        else:
            deltaDistX = abs_q16_16(q16_16_inverse(rayDirX[i]));
            stepX=1
            tmp = q16_16_sub(to_q16_16(mapX+1), posX)
            sideDistX = q16_16_mul(tmp, deltaDistX)

        if rayDirY[i]==to_q16_16(0):
            stepY = 1
            tmp = q16_16_sub(to_q16_16(mapY+1), posY)
            sideDistY = q16_16_mul(tmp, deltaDistY)
        elif rayDirY[i] < to_q16_16(0):
            deltaDistY = abs_q16_16(q16_16_inverse(rayDirY[i]));
            stepY = -1
            tmp = q16_16_sub(posY,to_q16_16(mapY))
            sideDistY = q16_16_mul(tmp, deltaDistY)
        else:
            deltaDistY = abs_q16_16(q16_16_inverse(rayDirY[i]));
            stepY = 1
            tmp = q16_16_sub(to_q16_16(mapY+1), posY)
            sideDistY = q16_16_mul(tmp, deltaDistY)


        while(hitInternal == False):
            if sideDistX < sideDistY:
                sideDistX = q16_16_add(sideDistX, deltaDistX)
                mapX += stepX
                sideHit = False
            else:
                sideDistY = q16_16_add(sideDistY, deltaDistY)
                mapY += stepY
                sideHit = True

            if(gridMap[mapX][mapY] > 0):
                hitInternal = True

        if sideHit == False:
            perpWallDist = q16_16_sub(sideDistX, deltaDistX)
        else:
            perpWallDist = q16_16_sub(sideDistY, deltaDistY)
        wallHeight = q16_16_div(HEIGHT, perpWallDist)
        #wallHeight *= 2
        if zoom:
            wallHeight *=2
        
        wallHeight = from_q16_16(wallHeight)
        drawStart = -wallHeight / 2 + 490/2 - 30
        if drawStart <0:
            drawStart = 0;
        drawEnd = wallHeight / 2 + 490/2
        if drawEnd >= 490:
            drawEnd = 490 - 1


        color = 100

        if sideHit == True:
            color = color - color/4

        if gridMap[mapX][mapY] == 2:
            pygame.draw.line(screen, (color*2, 0, 0), (i, drawStart), (i, drawEnd), width = 1)
        elif gridMap[mapX][mapY] == 3:
            pygame.draw.line(screen, (0, color*2, 0), (i, drawStart), (i, drawEnd), width = 1)
        else:
            pygame.draw.line(screen, (color, color, color), (i, drawStart), (i, drawEnd), width = 1)


def handle_input(gridMap):
    global posX, posY, dirX, dirY, planeX, planeY
    keys = pygame.key.get_pressed()
    speed = to_q16_16(0.1)

    cos = to_q16_16(0.99875026)
    sin = to_q16_16(0.0499792)

    if keys[pygame.K_UP]:
        if gridMap[int(from_q16_16(posX +q16_16_mul(dirX, speed)))][int(from_q16_16(posY))] == 0:
            posX = posX + q16_16_mul(dirX,speed)
        if gridMap[int(from_q16_16(posX))][int(from_q16_16(posY+q16_16_mul(dirY,speed)))] == 0:
            posY = posY + q16_16_mul(dirY,speed)
    if keys[pygame.K_DOWN]:
        if gridMap[int(from_q16_16(posX -  q16_16_mul(dirX,speed)))][int(from_q16_16(posY))] == 0:
            posX = posX - q16_16_mul(dirX,speed)
        if gridMap[int(from_q16_16(posX))][int(from_q16_16(posY-q16_16_mul(dirY,speed)))] == 0:
            posY = posY - q16_16_mul(dirY,speed)

    if keys[pygame.K_RIGHT]:
        oldDirX = dirX
        dirX = q16_16_mul(dirX, cos) +  q16_16_mul(dirY, sin)
        dirY = q16_16_mul(dirY, cos) - q16_16_mul(oldDirX, sin)

        oldPlaneX = planeX
        planeX = q16_16_mul(planeX, cos) + q16_16_mul(planeY, sin)
        planeY = q16_16_mul(planeY, cos) - q16_16_mul(oldPlaneX, sin)

    if keys[pygame.K_LEFT]:
        oldDirX = dirX
        dirX = q16_16_mul(dirX, cos) - q16_16_mul(dirY, sin)
        dirY = q16_16_mul(oldDirX, sin) + q16_16_mul(dirY, cos)

        oldPlaneX = planeX
        planeX = q16_16_mul(planeX,cos) - q16_16_mul(planeY,sin)
        planeY = q16_16_mul(oldPlaneX,sin) + q16_16_mul(planeY,cos)


if __name__ == "__main__":
    for i in range(10):
        print(i)
    pygame.init()
    screen = pygame.display.set_mode((780, 490))
    clock = pygame.time.Clock()
    """
    gridMap = [
            [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1],
            [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        ]
    
    """
    """
    gridMap = [
            [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            [1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1],
            [1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1],
            [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1],
            [1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1],
            [1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1],
            [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1],
            [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
            [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1],
            [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1],
            [1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1],
            [1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1],
            [1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1],
            [1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1],
            [1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1],
            [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 3, 3, 3, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]     
        ]

    """

    gridMap =[
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 0, 0, 1],
		[1, 0, 1, 0, 1, 0, 0, 1],
		[1, 0, 1, 0, 1, 0, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 1, 1, 1, 1, 1, 1, 1]
        ];
    

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_z:
                    planeX /= 2
                    planeY /= 2
                    zoom = True
            elif event.type == pygame.KEYUP:
                if event.key == pygame.K_z:
                    planeX *= 2
                    planeY *= 2
                    zoom = False

        pygame.draw.rect(screen, (0, 120, 255), (0, 0, 780, 490 // 2))
        pygame.draw.rect(screen, (124, 95, 46), (0, 490 // 2, 780, 490 // 2))
        handle_input(gridMap)
        game(screen, gridMap)
        pygame.display.flip()
        clock.tick(60)

