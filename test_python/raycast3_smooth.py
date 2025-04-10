import numpy as np
import math
import pygame

# Initialize map and player settings
MAP = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
]

WIDTH, HEIGHT = 1200, 400
FOV = math.pi / 3
RAYS = 120
MAX_DEPTH = 16
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GREEN = (0, 255, 0)
RED = (255, 0, 0)
GRAY = (100, 100, 100)

player_x, player_y = 3.5, 3.5
player_angle = 0

pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
clock = pygame.time.Clock()

def cast_rays():
    delta_angle = FOV / RAYS
    ray_angle = player_angle - FOV / 2
    texture_width = WIDTH // (2 * RAYS)
    for ray in range(RAYS):
        sin_a = math.sin(ray_angle)
        cos_a = math.cos(ray_angle)

        distance = 0
        while distance < MAX_DEPTH:
            distance += 0.01
            x = int(player_x + distance * cos_a)
            y = int(player_y + distance * sin_a)
            if MAP[y][x] == 1:
                break

        wall_height = int(HEIGHT / (distance * math.cos(ray_angle - player_angle)))
        color = 255 - min(255, int(distance * 20))

        # Draw vertical line for smoother walls
        start_x = WIDTH // 2 + ray * texture_width
        for i in range(texture_width):
            pygame.draw.line(screen, (color, color, color), (start_x + i, HEIGHT // 2 - wall_height // 2), (start_x + i, HEIGHT // 2 + wall_height // 2))

        ray_angle += delta_angle

def draw_map():
    map_size = 200
    cell_size = map_size // len(MAP)
    for y, row in enumerate(MAP):
        for x, cell in enumerate(row):
            color = WHITE if cell == 0 else BLACK
            pygame.draw.rect(screen, color, (x * cell_size, y * cell_size, cell_size, cell_size))
            pygame.draw.rect(screen, GRAY, (x * cell_size, y * cell_size, cell_size, cell_size), 1)
    player_pos = (int(player_x * cell_size), int(player_y * cell_size))
    pygame.draw.circle(screen, RED, player_pos, 5)

    start_angle = player_angle - FOV / 2
    for i in range(RAYS):
        angle = start_angle + i * (FOV / RAYS)
        end_x = int(player_pos[0] + math.cos(angle) * 100)
        end_y = int(player_pos[1] + math.sin(angle) * 100)
        pygame.draw.line(screen, GREEN, player_pos, (end_x, end_y))

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
    draw_map()
    cast_rays()

    pygame.display.flip()
    clock.tick(60)
