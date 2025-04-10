import numpy as np
import math
import pygame

# Initialize map and player settings
MAP = [
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1]
]

WIDTH, HEIGHT = 800, 400
FOV = math.pi / 3
RAYS = 120
MAX_DEPTH = 16

player_x, player_y = 3.5, 3.5
player_angle = 0

pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
clock = pygame.time.Clock()

def cast_rays():
    delta_angle = FOV / RAYS
    ray_angle = player_angle - FOV / 2
    for ray in range(RAYS):
        sin_a = math.sin(ray_angle)
        cos_a = math.cos(ray_angle)
        
        # Ray distance
        distance = 0
        while distance < MAX_DEPTH:
            distance += 0.1
            x = int(player_x + distance * cos_a)
            y = int(player_y + distance * sin_a)
            if MAP[y][x] == 1:
                break

        # Project wall height
        wall_height = int(HEIGHT / (distance * math.cos(ray_angle - player_angle)))

        # Calculate screen position
        color = 255 - min(255, int(distance * 20))
        pygame.draw.rect(screen, (color, color, color), (ray * (WIDTH // RAYS), HEIGHT // 2 - wall_height // 2, WIDTH // RAYS, wall_height))

        ray_angle += delta_angle

def handle_input():
    global player_x, player_y, player_angle
    keys = pygame.key.get_pressed()
    speed = 0.1
    rot_speed = 0.05

    if keys[pygame.K_UP]:
        player_x += math.cos(player_angle) * speed
        player_y += math.sin(player_angle) * speed
    if keys[pygame.K_DOWN]:
        player_x -= math.cos(player_angle) * speed
        player_y -= math.sin(player_angle) * speed
    if keys[pygame.K_LEFT]:
        player_angle -= rot_speed
    if keys[pygame.K_RIGHT]:
        player_angle += rot_speed

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((0, 0, 0))
    handle_input()
    cast_rays()

    pygame.display.flip()
    clock.tick(60)
