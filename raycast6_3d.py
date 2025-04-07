import numpy as np
import math
import pygame
import time

# Initialize map and player settings
MAP = [
    [
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
    ],
    [
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
player_x, player_y, player_z = 3.5, 3.5, 0
player_angle = 0
look_offset = 0  # Look up/down offset

pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
clock = pygame.time.Clock()
pygame.event.set_grab(True)
pygame.mouse.set_visible(False)

def handle_input():
    global player_x, player_y, player_z, player_angle, look_offset
    speed = 0.1

    keys = pygame.key.get_pressed()
    if keys[pygame.K_UP]:
        player_x += math.cos(player_angle) * speed
        player_y += math.sin(player_angle) * speed
    if keys[pygame.K_DOWN]:
        player_x -= math.cos(player_angle) * speed
        player_y -= math.sin(player_angle) * speed
    if keys[pygame.K_SPACE]:
        player_z = min(player_z + speed, 1)  # Limit to top layer
    if keys[pygame.K_LSHIFT]:
        player_z = max(player_z - speed, 0)  # Limit to bottom layer

    mouse_dx, mouse_dy = pygame.mouse.get_rel()
    player_angle += mouse_dx * 0.002
    look_offset -= mouse_dy * 0.5
    look_offset = max(-HEIGHT // 4, min(HEIGHT // 4, look_offset))

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((0, 0, 0))
    handle_input()

    pygame.display.flip()
    clock.tick(60)
