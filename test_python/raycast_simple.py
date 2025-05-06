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
RAYS = 100
MAX_DEPTH = 16
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GREEN = (0, 255, 0)
RED = (255, 0, 0)
GRAY = (100, 100, 100)

player_x, player_y = 3.5, 3.5
player_angle = 0

LUT_SIZE = 1024
PI2 = 2 * math.pi

# Precompute LUTs for sin and cos
sin_lut = [math.sin(2 * math.pi * i / LUT_SIZE) for i in range(LUT_SIZE)]
cos_lut = [math.cos(2 * math.pi * i / LUT_SIZE) for i in range(LUT_SIZE)]

def sin_approx(angle):
    index = int((angle % PI2) / PI2 * LUT_SIZE) % LUT_SIZE
    return sin_lut[index]

def cos_approx(angle):
    index = int((angle % PI2) / PI2 * LUT_SIZE) % LUT_SIZE
    return cos_lut[index]


pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
clock = pygame.time.Clock()

def handle_input():
    global player_x, player_y, player_angle
    keys = pygame.key.get_pressed()
    speed = 0.1
    rot_speed = 0.05

    if keys[pygame.K_UP]:
        player_x += cos_approx(player_angle) * speed
        player_y += sin_approx(player_angle) * speed
    if keys[pygame.K_DOWN]:
        player_x -= cos_approx(player_angle) * speed
        player_y -= sin_approx(player_angle) * speed

    if keys[pygame.K_LEFT]:
        player_angle -= rot_speed
    if keys[pygame.K_RIGHT]:
        player_angle += rot_speed


def cast_rays():
    delta_angle = FOV / RAYS
    ray_angle = player_angle - FOV / 2
    texture_width = WIDTH // RAYS
    raycast_height = int(HEIGHT * 0.8)  # Upper 80% of the window
    for ray in range(RAYS):
        sin_a = sin_approx(ray_angle)
        cos_a = cos_approx(ray_angle)

        distance = 0
        while distance < MAX_DEPTH:
            distance += 0.01
            x = int(player_x + distance * cos_a)
            y = int(player_y + distance * sin_a)
            if MAP[y][x] == 1:
                break

        wall_height = int(raycast_height / (distance * math.cos(ray_angle - player_angle)))
        color = 255 - min(255, int(distance * 20))

        # Draw vertical line for smoother walls
        start_x = ray * texture_width
        for i in range(texture_width):
            pygame.draw.line(screen, (color, color, color), (start_x + i, raycast_height // 2 - wall_height // 2), (start_x + i, raycast_height // 2 + wall_height // 2))

        ray_angle += delta_angle

def draw_map():
    map_height = int(HEIGHT * 0.2)  # Bottom 20% of the window
    map_width = WIDTH
    cell_size = min(map_height // len(MAP), map_width // len(MAP[0]))
    offset_y = HEIGHT - map_height  # Start drawing from the bottom part of the window

    for y, row in enumerate(MAP):
        for x, cell in enumerate(row):
            color = BLACK if cell == 0 else WHITE
            pygame.draw.rect(screen, color, (x * cell_size, offset_y + y * cell_size, cell_size, cell_size))
            pygame.draw.rect(screen, GRAY, (x * cell_size, offset_y + y * cell_size, cell_size, cell_size), 1)

    player_pos = (int(player_x * cell_size), int(offset_y + player_y * cell_size))
    pygame.draw.circle(screen, RED, player_pos, 5)

    start_angle = player_angle - FOV / 2
    for i in range(RAYS):
        angle = start_angle + i * (FOV / RAYS)
        end_x = int(player_pos[0] + cos_approx(angle) * 100)
        end_y = int(player_pos[1] + sin_approx(angle) * 100)

        pygame.draw.line(screen, GREEN, player_pos, (end_x, end_y))

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((0, 0, 0))
    handle_input()
    cast_rays()
    draw_map()

    pygame.display.flip()
    clock.tick(60)
