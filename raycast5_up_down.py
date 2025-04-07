import numpy as np
import math
import pygame
import time

# Initialize map and player settings
MAP = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
]

WIDTH, HEIGHT = 1200, 400
FOV = math.pi / 3
RAYS = 120//2
MAX_DEPTH = 16
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GREEN = (0, 255, 0)
RED = (255, 0, 0)
GRAY = (100, 100, 100)

y_offset = 0  # Vertical look offset
player_x, player_y = 3.5, 3.5
player_angle = 0
look_offset = 0  # Look up/down offset

# Moving object state
moving_obj_pos = 8
moving_obj_dir = 1
last_move_time = time.time()

pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
clock = pygame.time.Clock()
pygame.event.set_grab(True)
pygame.mouse.set_visible(False)

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
            if MAP[y][x] == 1 or MAP[y][x] == 9:
                break

        wall_height = int(HEIGHT / (distance * math.cos(ray_angle - player_angle)))
        color = 255 - min(255, int(distance * 20))

        # Draw vertical line for smoother walls with height offset
        start_x = WIDTH // 2 + ray * texture_width
        for i in range(texture_width):
            pygame.draw.line(screen, (color, color, color), (start_x + i, HEIGHT // 2 - wall_height // 2 + y_offset + look_offset), (start_x + i, HEIGHT // 2 + wall_height // 2 + y_offset + look_offset))

        ray_angle += delta_angle

def handle_input():
    global player_x, player_y, player_angle, look_offset
    speed = 0.1

    keys = pygame.key.get_pressed()
    if keys[pygame.K_UP]:
        player_x += math.cos(player_angle) * speed
        player_y += math.sin(player_angle) * speed
    if keys[pygame.K_DOWN]:
        player_x -= math.cos(player_angle) * speed
        player_y -= math.sin(player_angle) * speed

    # Mouse movement for looking around
    mouse_dx, mouse_dy = pygame.mouse.get_rel()
    player_angle += mouse_dx * 0.002
    look_offset -= mouse_dy * 0.5  # Adjust look offset for up/down movement
    look_offset = max(-HEIGHT // 4, min(HEIGHT // 4, look_offset))  # Clamp look movement

def update_moving_object():
    global moving_obj_pos, moving_obj_dir, last_move_time
    current_time = time.time()
    if current_time - last_move_time >= 1:
        last_move_time = current_time

        # Clear old position
        for y in range(len(MAP)):
            for x in range(len(MAP[0])):
                if MAP[y][x] == 9:
                    MAP[y][x] = 0

        # Update position
        moving_obj_pos += moving_obj_dir
        if moving_obj_pos == 9:
            moving_obj_dir = -1
        elif moving_obj_pos == 6:
            moving_obj_dir = 1

        MAP[5][moving_obj_pos] = 9

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((0, 0, 0))
    handle_input()
    update_moving_object()
    cast_rays()

    pygame.display.flip()
    clock.tick(60)
